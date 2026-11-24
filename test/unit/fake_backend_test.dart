// PRUEBAS UNITARIAS: API simulada (FakeBackend) usada a través del
// HttpAuthService real. Comprueba que el "servidor" responde como uno real.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/services/api_exceptions.dart';
import 'package:flutter23/services/fake_backend.dart';
import 'package:flutter23/services/http_auth_service.dart';

void main() {
  late FakeBackend backend;
  late HttpAuthService service;

  setUp(() {
    backend = FakeBackend(latency: Duration.zero);
    service = HttpAuthService(
      client: backend.client,
      baseUrl: FakeBackend.baseUrl,
    );
  });

  test('el usuario demo puede iniciar sesión', () async {
    final session = await service.login(
      FakeBackend.demoEmail,
      FakeBackend.demoPassword,
    );
    expect(session.user.name, 'Usuario Demo');
  });

  test('incluye cinco usuarios disponibles al iniciar', () async {
    const emails = [
      FakeBackend.demoEmail,
      'sofia@gravity.com',
      'luis@gravity.com',
      'maria@gravity.com',
      'carlos@gravity.com',
    ];

    for (final email in emails) {
      final session = await service.login(email, FakeBackend.demoPassword);
      expect(session.user.email, email);
    }
  });

  test('contraseña incorrecta -> AuthException', () async {
    await expectLater(
      service.login(FakeBackend.demoEmail, 'Incorrecta1!'),
      throwsA(isA<AuthException>()),
    );
  });

  test('correo inexistente -> AuthException', () async {
    await expectLater(
      service.login('nadie@gravity.com', 'Gravity123!'),
      throwsA(isA<AuthException>()),
    );
  });

  test('registro + login + perfil + logout', () async {
    final registro =
        await service.register('Ana Pérez', 'ana@gravity.com', 'Segura123!');
    expect(registro.user.email, 'ana@gravity.com');

    final login = await service.login('ana@gravity.com', 'Segura123!');
    final perfil = await service.getProfile(login.token);
    expect(perfil.name, 'Ana Pérez');

    await service.logout(login.token);
    await expectLater(
      service.getProfile(login.token),
      throwsA(isA<AuthException>()),
    );
  });

  test('registrar un correo existente -> ConflictException', () async {
    await expectLater(
      service.register('Otro', FakeBackend.demoEmail, 'Segura123!'),
      throwsA(isA<ConflictException>()),
    );
  });

  test('cada login genera un token distinto', () async {
    final a = await service.login(FakeBackend.demoEmail, FakeBackend.demoPassword);
    final b = await service.login(FakeBackend.demoEmail, FakeBackend.demoPassword);
    expect(a.token, isNot(b.token));
  });

  test('ruta inexistente -> 404', () async {
    final response = await backend.client
        .get(Uri.parse('${FakeBackend.baseUrl}/no-existe'));
    expect(response.statusCode, 404);
  });
}
