// PRUEBAS UNITARIAS + MOCKS: cliente de la API REST.
// Se simula el http.Client con Mocktail para devolver respuestas y errores
// HTTP sin necesidad de un servidor.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/services/api_exceptions.dart';
import 'package:flutter23/services/http_auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import '../mocks/mocks.dart';
import '../mocks/test_data.dart';

void main() {
  late MockHttpClient client;
  late HttpAuthService service;

  setUpAll(registerMockFallbacks);

  setUp(() {
    client = MockHttpClient();
    service = HttpAuthService(client: client, baseUrl: 'https://api.test');
  });

  /// Configura la respuesta de cualquier POST.
  void stubPost(Future<http.Response> Function() answer) {
    when(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) => answer());
  }

  http.Response jsonResponse(Object body, int status) =>
      http.Response(jsonEncode(body), status);

  group('respuestas exitosas', () {
    test('login 200 devuelve la sesión', () async {
      stubPost(() async => jsonResponse(kSessionJson, 200));

      final session = await service.login(kEmail, kPassword);

      expect(session.token, 'token-de-prueba-123');
      expect(session.user, kUser);
    });

    test('login envía JSON a /auth/login con las cabeceras correctas', () async {
      stubPost(() async => jsonResponse(kSessionJson, 200));

      await service.login(kEmail, kPassword);

      final captured = verify(
        () => client.post(
          captureAny(),
          headers: captureAny(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      final uri = captured[0] as Uri;
      final headers = captured[1] as Map<String, String>;
      final body = jsonDecode(captured[2] as String) as Map<String, dynamic>;

      expect(uri.toString(), 'https://api.test/auth/login');
      expect(headers['Content-Type'], 'application/json');
      expect(body, {'email': kEmail, 'password': kPassword});
    });

    test('register 201 devuelve la sesión', () async {
      stubPost(() async => jsonResponse(kSessionJson, 201));

      final session = await service.register('Usuario Demo', kEmail, kPassword);

      expect(session.user.name, 'Usuario Demo');
    });

    test('getProfile envía el token como Bearer', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse(kUserJson, 200));

      final user = await service.getProfile('abc123');

      expect(user, kUser);
      final headers = verify(
        () => client.get(any(), headers: captureAny(named: 'headers')),
      ).captured.single as Map<String, String>;
      expect(headers['Authorization'], 'Bearer abc123');
    });

    test('logout 204 termina sin errores', () async {
      when(() => client.post(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 204));

      await expectLater(service.logout('abc123'), completes);
    });
  });

  group('errores HTTP', () {
    test('401 -> AuthException con el mensaje del servidor', () async {
      stubPost(() async => jsonResponse({'message': 'Credenciales inválidas'}, 401));

      await expectLater(
        service.login(kEmail, 'Mala123!'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.message, 'message', 'Credenciales inválidas'),
        ),
      );
    });

    test('409 -> ConflictException', () async {
      stubPost(() async => jsonResponse({'message': 'Ya existe'}, 409));

      await expectLater(
        service.register('Ana', kEmail, kPassword),
        throwsA(isA<ConflictException>()),
      );
    });

    test('400 -> ValidationException', () async {
      stubPost(() async => jsonResponse({'message': 'Datos incompletos'}, 400));

      await expectLater(
        service.login(kEmail, kPassword),
        throwsA(isA<ValidationException>()),
      );
    });

    test('500 -> ServerException con statusCode 500', () async {
      stubPost(() async => http.Response('Internal Server Error', 500));

      await expectLater(
        service.login(kEmail, kPassword),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('200 con JSON inválido -> ServerException', () async {
      stubPost(() async => http.Response('esto no es json', 200));

      await expectLater(
        service.login(kEmail, kPassword),
        throwsA(isA<ServerException>()),
      );
    });

    test('200 sin token -> ServerException', () async {
      stubPost(() async => jsonResponse({'user': kUserJson}, 200));

      await expectLater(
        service.login(kEmail, kPassword),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('errores de conexión', () {
    test('SocketException (sin internet) -> NetworkException', () async {
      stubPost(() async => throw const SocketException('Failed host lookup'));

      await expectLater(
        service.login(kEmail, kPassword),
        throwsA(isA<NetworkException>()),
      );
    });

    test('ClientException (conexión rechazada) -> NetworkException', () async {
      stubPost(() async => throw http.ClientException('Connection refused'));

      await expectLater(
        service.login(kEmail, kPassword),
        throwsA(isA<NetworkException>()),
      );
    });

    test('el servidor tarda demasiado -> NetworkException (timeout)', () async {
      final lento = HttpAuthService(
        client: client,
        baseUrl: 'https://api.test',
        timeout: const Duration(milliseconds: 50),
      );
      stubPost(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return jsonResponse(kSessionJson, 200);
      });

      await expectLater(
        lento.login(kEmail, kPassword),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
