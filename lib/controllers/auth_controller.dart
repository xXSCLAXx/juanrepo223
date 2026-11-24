import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../models/user.dart';
import '../services/api_exceptions.dart';
import '../services/auth_service.dart';
import '../validators/validators.dart';

enum AuthStatus { unauthenticated, loading, authenticated }

/// Mensajes que ve el usuario (las pruebas los usan como constantes).
abstract final class AuthMessages {
  static const String invalidCredentials = 'Correo o contraseña incorrectos';
  static const String tooManyAttempts =
      'Demasiados intentos fallidos. Intenta de nuevo en unos minutos.';
  static const String noConnection =
      'Sin conexión. Revisa tu internet e intenta de nuevo.';
  static const String serverError = 'Error del servidor. Intenta más tarde.';
  static const String emailAlreadyRegistered = 'Este correo ya está registrado';
  static const String noSession = 'No hay una sesión activa';
}

/// Lógica de negocio de autenticación. No sabe nada de widgets.
///
/// Reglas de negocio:
/// 1. No se llama a la API si los datos no son válidos.
/// 2. Mientras hay una petición en curso se ignoran nuevas (evita doble envío).
/// 3. Tras [maxAttempts] intentos fallidos se bloquea el login [lockDuration].
/// 4. El correo se normaliza (sin espacios y en minúsculas).
/// 5. Al cerrar sesión se borra la sesión local aunque la API falle.
class AuthController extends ChangeNotifier {
  AuthController(
    this._service, {
    DateTime Function()? clock,
    this.maxAttempts = 5,
    this.lockDuration = const Duration(minutes: 5),
  }) : _clock = clock ?? DateTime.now;

  final AuthService _service;
  final DateTime Function() _clock; // inyectable para probar el bloqueo
  final int maxAttempts;
  final Duration lockDuration;

  AuthStatus _status = AuthStatus.unauthenticated;
  AuthSession? _session;
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  User? get currentUser => _session?.user;
  String? get errorMessage => _errorMessage;
  int get failedAttempts => _failedAttempts;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLocked {
    final until = _lockedUntil;
    return until != null && _clock().isBefore(until);
  }

  /// Devuelve `true` si el inicio de sesión fue exitoso.
  Future<bool> login(String email, String password) async {
    if (isLoading) return false; // regla 2
    if (isLocked) return _fail(AuthMessages.tooManyAttempts); // regla 3

    final inputError = Validators.email(email) ??
        Validators.notEmpty(
          password,
          message: ValidationMessages.passwordRequired,
        );
    if (inputError != null) return _fail(inputError); // regla 1

    _startLoading();
    try {
      _session = await _service.login(Validators.normalizeEmail(email), password);
      _failedAttempts = 0;
      _lockedUntil = null;
      _succeed();
      return true;
    } on AuthException {
      _failedAttempts++;
      if (_failedAttempts >= maxAttempts) {
        _lockedUntil = _clock().add(lockDuration);
        _failedAttempts = 0;
        return _fail(AuthMessages.tooManyAttempts);
      }
      return _fail(AuthMessages.invalidCredentials);
    } on NetworkException {
      return _fail(AuthMessages.noConnection);
    } on ApiException {
      return _fail(AuthMessages.serverError);
    }
  }

  /// Devuelve `true` si el registro fue exitoso (queda con sesión iniciada).
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (isLoading) return false;

    final inputError = Validators.name(name) ??
        Validators.email(email) ??
        Validators.password(password) ??
        Validators.confirmPassword(confirmPassword, password);
    if (inputError != null) return _fail(inputError);

    _startLoading();
    try {
      _session = await _service.register(
        name.trim(),
        Validators.normalizeEmail(email),
        password,
      );
      _succeed();
      return true;
    } on ConflictException {
      return _fail(AuthMessages.emailAlreadyRegistered);
    } on ValidationException catch (e) {
      return _fail(e.message);
    } on NetworkException {
      return _fail(AuthMessages.noConnection);
    } on ApiException {
      return _fail(AuthMessages.serverError);
    }
  }

  /// Pide el perfil actualizado a la API (GET /users/me).
  Future<User> fetchProfile() async {
    final current = _session;
    if (current == null) {
      throw const AuthException(AuthMessages.noSession);
    }
    final user = await _service.getProfile(current.token);
    if (_session != null) {
      _session = current.copyWith(user: user);
      notifyListeners();
    }
    return user;
  }

  /// Cierra sesión. Primero borra la sesión local (regla 5) y luego avisa a la API.
  Future<void> logout() async {
    final token = _session?.token;
    _session = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    if (token == null) return;
    try {
      await _service.logout(token);
    } on ApiException {
      // La sesión local ya se cerró; si la API falla, el token expirará solo.
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------

  void _startLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _succeed() {
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  bool _fail(String message) {
    _status = _session == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    _errorMessage = message;
    notifyListeners();
    return false;
  }
}
