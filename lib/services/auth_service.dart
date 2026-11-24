import '../models/auth_session.dart';
import '../models/user.dart';

/// Contrato del servicio de autenticación.
///
/// El resto de la app depende de esta interfaz y no de una implementación
/// concreta. Así, en las pruebas se reemplaza por un mock (mocktail).
abstract class AuthService {
  /// POST /auth/login
  Future<AuthSession> login(String email, String password);

  /// POST /auth/register
  Future<AuthSession> register(String name, String email, String password);

  /// GET /users/me
  Future<User> getProfile(String token);

  /// POST /auth/logout
  Future<void> logout(String token);
}
