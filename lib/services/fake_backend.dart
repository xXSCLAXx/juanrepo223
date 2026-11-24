import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// API REST SIMULADA en memoria.
///
/// Se comporta como un servidor real (rutas, códigos HTTP, JSON, latencia),
/// pero no necesita internet. La app la usa mientras no exista la API real.
///
/// Endpoints:
///   POST /auth/register  {name, email, password} -> 201 {token, user} | 400 | 409
///   POST /auth/login     {email, password}       -> 200 {token, user} | 400 | 401
///   GET  /users/me       (Authorization: Bearer) -> 200 user | 401
///   POST /auth/logout    (Authorization: Bearer) -> 204
///
/// Usuario de prueba: demo@gravity.com / Gravity123!
///
/// IMPORTANTE: un backend real NUNCA guarda contraseñas en texto plano;
/// debe guardar un hash (bcrypt, argon2). Aquí se simplifica por ser un simulador.
class FakeBackend {
  FakeBackend({
    this.latency = const Duration(milliseconds: 400),
    bool seedDemoUser = true,
  }) {
    if (seedDemoUser) {
      _users[demoEmail] = const _StoredUser(
        id: '1',
        name: 'Usuario Demo',
        email: demoEmail,
        password: demoPassword,
      );
      _users['sofia@gravity.com'] = const _StoredUser(
        id: '2',
        name: 'Sofía Herrera',
        email: 'sofia@gravity.com',
        password: demoPassword,
      );
      _users['luis@gravity.com'] = const _StoredUser(
        id: '3',
        name: 'Luis Gómez',
        email: 'luis@gravity.com',
        password: demoPassword,
      );
      _users['maria@gravity.com'] = const _StoredUser(
        id: '4',
        name: 'María Torres',
        email: 'maria@gravity.com',
        password: demoPassword,
      );
      _users['carlos@gravity.com'] = const _StoredUser(
        id: '5',
        name: 'Carlos Ruiz',
        email: 'carlos@gravity.com',
        password: demoPassword,
      );
    }
  }

  static const String baseUrl = 'https://api.gravity.fake';
  static const String demoEmail = 'demo@gravity.com';
  static const String demoPassword = 'Gravity123!';

  /// Retardo artificial para simular la red.
  final Duration latency;

  final Map<String, _StoredUser> _users = {};
  final Map<String, String> _tokens = {}; // token -> email
  final Random _random = Random.secure();
  int _nextId = 2;

  /// Cliente HTTP que responde como si fuera el servidor.
  late final http.Client client = MockClient(_handle);

  /// Número de peticiones recibidas (útil en pruebas de regresión).
  int requestCount = 0;

  Future<http.Response> _handle(http.Request request) async {
    requestCount++;
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    try {
      final route = '${request.method} ${request.url.path}';
      switch (route) {
        case 'POST /auth/register':
          return _register(request);
        case 'POST /auth/login':
          return _login(request);
        case 'GET /users/me':
          return _me(request);
        case 'POST /auth/logout':
          return _logout(request);
        default:
          return _json(404, {'message': 'Ruta no encontrada'});
      }
    } on FormatException {
      return _json(400, {'message': 'JSON inválido'});
    }
  }

  http.Response _register(http.Request request) {
    final body = _body(request);
    final name = (body['name'] as String?)?.trim() ?? '';
    final email = (body['email'] as String?)?.trim().toLowerCase() ?? '';
    final password = body['password'] as String? ?? '';
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return _json(400, {'message': 'Datos incompletos'});
    }
    if (_users.containsKey(email)) {
      return _json(409, {'message': 'El correo ya está registrado'});
    }
    final user = _StoredUser(
      id: '${_nextId++}',
      name: name,
      email: email,
      password: password,
    );
    _users[email] = user;
    return _json(201, {'token': _newToken(email), 'user': user.toJson()});
  }

  http.Response _login(http.Request request) {
    final body = _body(request);
    final email = (body['email'] as String?)?.trim().toLowerCase() ?? '';
    final password = body['password'] as String? ?? '';
    if (email.isEmpty || password.isEmpty) {
      return _json(400, {'message': 'Datos incompletos'});
    }
    final user = _users[email];
    // SEGURIDAD: mismo mensaje si el correo no existe o la clave es incorrecta,
    // para no revelar qué correos están registrados.
    if (user == null || user.password != password) {
      return _json(401, {'message': 'Credenciales inválidas'});
    }
    return _json(200, {'token': _newToken(email), 'user': user.toJson()});
  }

  http.Response _me(http.Request request) {
    final email = _tokens[_bearer(request)];
    final user = email == null ? null : _users[email];
    if (user == null) {
      return _json(401, {'message': 'Token inválido o expirado'});
    }
    return _json(200, user.toJson());
  }

  http.Response _logout(http.Request request) {
    _tokens.remove(_bearer(request));
    return http.Response('', 204);
  }

  // ---------------------------------------------------------------------------

  Map<String, dynamic> _body(http.Request request) {
    final data = jsonDecode(request.body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Se esperaba un objeto JSON');
    }
    return data;
  }

  String? _bearer(http.Request request) {
    final header = request.headers['Authorization'] ??
        request.headers['authorization'];
    if (header == null || !header.startsWith('Bearer ')) return null;
    return header.substring('Bearer '.length);
  }

  String _newToken(String email) {
    final token = List.generate(32, (_) => _random.nextInt(16).toRadixString(16))
        .join();
    _tokens[token] = email;
    return token;
  }

  http.Response _json(int status, Map<String, dynamic> body) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
}

class _StoredUser {
  const _StoredUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  final String id;
  final String name;
  final String email;
  final String password;

  /// La contraseña NO se incluye en las respuestas.
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}
