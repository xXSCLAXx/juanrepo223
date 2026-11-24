import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/auth_session.dart';
import '../models/user.dart';
import 'api_exceptions.dart';
import 'auth_service.dart';

/// Implementación real del [AuthService] que consume una API REST.
///
/// Recibe el [http.Client] por constructor (inyección de dependencias):
/// - En la app: un cliente real o el [FakeBackend] (API simulada).
/// - En las pruebas: un mock de mocktail.
class HttpAuthService implements AuthService {
  HttpAuthService({
    required http.Client client,
    required String baseUrl,
    Duration timeout = const Duration(seconds: 10),
    bool allowInsecure = false,
  })  : _client = client,
        _baseUrl = baseUrl,
        _timeout = timeout {
    // SEGURIDAD: las credenciales solo viajan por HTTPS.
    if (!allowInsecure && !baseUrl.startsWith('https://')) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'Debe usar https://');
    }
  }

  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  @override
  Future<AuthSession> login(String email, String password) async {
    final response = await _send(
      () => _client.post(
        _uri('/auth/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    _check(response);
    return _parse(() => AuthSession.fromJson(_decode(response)));
  }

  @override
  Future<AuthSession> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await _send(
      () => _client.post(
        _uri('/auth/register'),
        headers: _headers(),
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ),
    );
    _check(response);
    return _parse(() => AuthSession.fromJson(_decode(response)));
  }

  @override
  Future<User> getProfile(String token) async {
    final response = await _send(
      () => _client.get(_uri('/users/me'), headers: _headers(token)),
    );
    _check(response);
    return _parse(() => User.fromJson(_decode(response)));
  }

  @override
  Future<void> logout(String token) async {
    final response = await _send(
      () => _client.post(_uri('/auth/logout'), headers: _headers(token)),
    );
    _check(response);
  }

  // ---------------------------------------------------------------------------
  // Utilidades privadas
  // ---------------------------------------------------------------------------

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Ejecuta la petición y traduce los errores de red a [NetworkException].
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado');
    } on SocketException {
      throw const NetworkException('Sin conexión a internet');
    } on http.ClientException {
      throw const NetworkException('No se pudo conectar con el servidor');
    }
  }

  /// Traduce los códigos HTTP de error a excepciones del dominio.
  void _check(http.Response response) {
    final code = response.statusCode;
    if (code >= 200 && code < 300) return;
    final message = _serverMessage(response);
    switch (code) {
      case 400:
      case 422:
        throw ValidationException(message);
      case 401:
      case 403:
        throw AuthException(message);
      case 409:
        throw ConflictException(message);
      default:
        throw ServerException(message, statusCode: code);
    }
  }

  String _serverMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Error ${response.statusCode}';
    } on FormatException {
      return 'Error ${response.statusCode}';
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Se esperaba un objeto JSON');
    }
    return data;
  }

  T _parse<T>(T Function() parser) {
    try {
      return parser();
    } on FormatException {
      throw const ServerException('Respuesta inválida del servidor');
    }
  }
}
