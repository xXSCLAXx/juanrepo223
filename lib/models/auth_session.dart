import 'user.dart';

/// Sesión activa: el usuario y el token que envía la API.
class AuthSession {
  const AuthSession({required this.user, required this.token});

  final User user;
  final String token;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final user = json['user'];
    if (token is! String || token.isEmpty || user is! Map<String, dynamic>) {
      throw const FormatException('Sesión inválida en la respuesta');
    }
    return AuthSession(user: User.fromJson(user), token: token);
  }

  AuthSession copyWith({User? user, String? token}) =>
      AuthSession(user: user ?? this.user, token: token ?? this.token);

  /// SEGURIDAD: el token nunca se imprime completo (logs, errores, consola).
  @override
  String toString() => 'AuthSession(user: ${user.email}, token: ***)';
}
