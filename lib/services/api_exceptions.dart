/// Errores que puede devolver la capa de servicios.
/// La UI nunca ve errores de HTTP crudos, solo estos tipos.
abstract class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => '$runtimeType(${statusCode ?? '-'}): $message';
}

/// Sin internet, servidor caído o tiempo de espera agotado.
class NetworkException extends ApiException {
  const NetworkException(super.message);
}

/// 401 / 403: credenciales incorrectas o token inválido.
class AuthException extends ApiException {
  const AuthException(super.message) : super(statusCode: 401);
}

/// 409: el recurso ya existe (por ejemplo, correo ya registrado).
class ConflictException extends ApiException {
  const ConflictException(super.message) : super(statusCode: 409);
}

/// 400 / 422: datos enviados inválidos.
class ValidationException extends ApiException {
  const ValidationException(super.message) : super(statusCode: 400);
}

/// 5xx o respuesta con formato inesperado.
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode});
}
