// Objetos simulados con Mocktail.
//
// Un "mock" es un objeto falso cuyo comportamiento definimos en cada prueba:
//   when(() => mock.metodo(...)).thenAnswer((_) async => valor);   // éxito
//   when(() => mock.metodo(...)).thenThrow(MiExcepcion());          // error
//   verify(() => mock.metodo(...)).called(1);                       // se llamó
//   verifyNever(() => mock.metodo(...));                            // no se llamó
import 'package:flutter23/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

/// Simula el servicio de autenticación (para controller y pantallas).
class MockAuthService extends Mock implements AuthService {}

/// Simula el cliente HTTP (para probar las respuestas de la API).
class MockHttpClient extends Mock implements http.Client {}

/// Mocktail necesita un valor "de reserva" para usar any() con tipos propios.
void registerMockFallbacks() {
  registerFallbackValue(Uri());
}
