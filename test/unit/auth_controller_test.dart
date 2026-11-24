// PRUEBAS UNITARIAS + MOCKS: reglas de negocio del AuthController.
// El servicio real se reemplaza por MockAuthService (mocktail).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/controllers/auth_controller.dart';
import 'package:flutter23/models/auth_session.dart';
import 'package:flutter23/models/user.dart';
import 'package:flutter23/services/api_exceptions.dart';
import 'package:flutter23/validators/validators.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mocks.dart';
import '../mocks/test_data.dart';

void main() {
  late MockAuthService service;
  late AuthController controller;
  late DateTime now;

  setUp(() {
    service = MockAuthService();
    now = DateTime(2026, 1, 1, 10);
    // Reloj controlado: así probamos el bloqueo sin esperar 5 minutos reales.
    controller = AuthController(service, clock: () => now);
  });

  void stubLoginOk() =>
      when(() => service.login(any(), any())).thenAnswer((_) async => kSession);

  void stubLoginError(ApiException e) =>
      when(() => service.login(any(), any())).thenThrow(e);

  group('login', () {
    test('éxito: queda autenticado con la sesión del servidor', () async {
      stubLoginOk();

      final ok = await controller.login(kEmail, kPassword);

      expect(ok, isTrue);
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.currentUser, kUser);
      expect(controller.errorMessage, isNull);
      verify(() => service.login(kEmail, kPassword)).called(1);
    });

    test('normaliza el correo antes de enviarlo', () async {
      stubLoginOk();

      await controller.login('  DEMO@Gravity.com ', kPassword);

      verify(() => service.login('demo@gravity.com', kPassword)).called(1);
    });

    test('correo inválido: muestra error y NO llama a la API', () async {
      final ok = await controller.login('correo-malo', kPassword);

      expect(ok, isFalse);
      expect(controller.errorMessage, ValidationMessages.emailInvalid);
      verifyNever(() => service.login(any(), any()));
    });

    test('contraseña vacía: NO llama a la API', () async {
      await controller.login(kEmail, '');

      expect(controller.errorMessage, ValidationMessages.passwordRequired);
      verifyNever(() => service.login(any(), any()));
    });

    test('credenciales incorrectas (401)', () async {
      stubLoginError(const AuthException('Credenciales inválidas'));

      final ok = await controller.login(kEmail, 'Incorrecta1!');

      expect(ok, isFalse);
      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.errorMessage, AuthMessages.invalidCredentials);
      expect(controller.failedAttempts, 1);
    });

    test('sin conexión', () async {
      stubLoginError(const NetworkException('Sin conexión a internet'));

      await controller.login(kEmail, kPassword);

      expect(controller.errorMessage, AuthMessages.noConnection);
    });

    test('error del servidor (500)', () async {
      stubLoginError(const ServerException('boom', statusCode: 500));

      await controller.login(kEmail, kPassword);

      expect(controller.errorMessage, AuthMessages.serverError);
    });

    test('cambia de estado: loading -> authenticated', () async {
      stubLoginOk();
      final estados = <AuthStatus>[];
      controller.addListener(() => estados.add(controller.status));

      await controller.login(kEmail, kPassword);

      expect(estados, [AuthStatus.loading, AuthStatus.authenticated]);
    });

    test('ignora un segundo login mientras el primero está en curso', () async {
      final completer = Completer<AuthSession>();
      when(() => service.login(any(), any()))
          .thenAnswer((_) => completer.future);

      final primero = controller.login(kEmail, kPassword);
      final segundo = await controller.login(kEmail, kPassword);
      completer.complete(kSession);

      expect(segundo, isFalse);
      expect(await primero, isTrue);
      verify(() => service.login(any(), any())).called(1);
    });
  });

  group('bloqueo por intentos fallidos (fuerza bruta)', () {
    test('se bloquea al 5º intento y no vuelve a llamar a la API', () async {
      stubLoginError(const AuthException('Credenciales inválidas'));

      for (var i = 0; i < 5; i++) {
        await controller.login(kEmail, 'Incorrecta1!');
      }
      expect(controller.isLocked, isTrue);
      expect(controller.errorMessage, AuthMessages.tooManyAttempts);

      await controller.login(kEmail, kPassword); // 6º intento
      verify(() => service.login(any(), any())).called(5);
    });

    test('4 intentos fallidos todavía NO bloquean (valor límite)', () async {
      stubLoginError(const AuthException('Credenciales inválidas'));

      for (var i = 0; i < 4; i++) {
        await controller.login(kEmail, 'Incorrecta1!');
      }

      expect(controller.isLocked, isFalse);
      expect(controller.failedAttempts, 4);
    });

    test('se desbloquea cuando pasa el tiempo de bloqueo', () async {
      stubLoginError(const AuthException('Credenciales inválidas'));
      for (var i = 0; i < 5; i++) {
        await controller.login(kEmail, 'Incorrecta1!');
      }

      now = now.add(const Duration(minutes: 5, seconds: 1));
      stubLoginOk();

      expect(controller.isLocked, isFalse);
      expect(await controller.login(kEmail, kPassword), isTrue);
    });

    test('un login exitoso reinicia el contador', () async {
      stubLoginError(const AuthException('Credenciales inválidas'));
      for (var i = 0; i < 3; i++) {
        await controller.login(kEmail, 'Incorrecta1!');
      }
      stubLoginOk();

      await controller.login(kEmail, kPassword);

      expect(controller.failedAttempts, 0);
    });
  });

  group('register', () {
    Future<bool> registrar({
      String name = kNewName,
      String email = kNewEmail,
      String password = kNewPassword,
      String? confirm,
    }) =>
        controller.register(
          name: name,
          email: email,
          password: password,
          confirmPassword: confirm ?? password,
        );

    test('éxito: crea la cuenta e inicia sesión', () async {
      when(() => service.register(any(), any(), any()))
          .thenAnswer((_) async => kNewSession);

      final ok = await registrar(name: '  Ana Pérez ', email: 'ANA@gravity.com');

      expect(ok, isTrue);
      expect(controller.currentUser, kNewUser);
      verify(() => service.register(kNewName, kNewEmail, kNewPassword))
          .called(1);
    });

    test('contraseñas distintas: NO llama a la API', () async {
      await registrar(confirm: 'Otra1234!');

      expect(controller.errorMessage, ValidationMessages.passwordsDontMatch);
      verifyNever(() => service.register(any(), any(), any()));
    });

    test('contraseña débil: NO llama a la API', () async {
      await registrar(password: 'Segura123');

      expect(controller.errorMessage, ValidationMessages.passwordSymbol);
      verifyNever(() => service.register(any(), any(), any()));
    });

    test('correo ya registrado (409)', () async {
      when(() => service.register(any(), any(), any()))
          .thenThrow(const ConflictException('El correo ya está registrado'));

      final ok = await registrar();

      expect(ok, isFalse);
      expect(controller.errorMessage, AuthMessages.emailAlreadyRegistered);
    });

    test('datos rechazados por el servidor (400) muestran su mensaje', () async {
      when(() => service.register(any(), any(), any()))
          .thenThrow(const ValidationException('Datos incompletos'));

      await registrar();

      expect(controller.errorMessage, 'Datos incompletos');
    });

    test('sin conexión', () async {
      when(() => service.register(any(), any(), any()))
          .thenThrow(const NetworkException('Sin conexión'));

      await registrar();

      expect(controller.errorMessage, AuthMessages.noConnection);
    });
  });

  group('logout', () {
    test('borra la sesión y avisa a la API con el token', () async {
      stubLoginOk();
      when(() => service.logout(any())).thenAnswer((_) async {});
      await controller.login(kEmail, kPassword);

      await controller.logout();

      expect(controller.session, isNull);
      expect(controller.status, AuthStatus.unauthenticated);
      verify(() => service.logout(kSession.token)).called(1);
    });

    test('cierra la sesión local aunque la API falle', () async {
      stubLoginOk();
      when(() => service.logout(any()))
          .thenThrow(const NetworkException('Sin conexión'));
      await controller.login(kEmail, kPassword);

      await controller.logout();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
    });

    test('sin sesión no llama a la API', () async {
      await controller.logout();

      verifyNever(() => service.logout(any()));
    });
  });

  group('fetchProfile', () {
    test('actualiza el usuario de la sesión con los datos de la API', () async {
      stubLoginOk();
      const actualizado = User(id: '1', name: 'Demo Actualizado', email: kEmail);
      when(() => service.getProfile(any())).thenAnswer((_) async => actualizado);
      await controller.login(kEmail, kPassword);

      final user = await controller.fetchProfile();

      expect(user, actualizado);
      expect(controller.currentUser!.name, 'Demo Actualizado');
      verify(() => service.getProfile(kSession.token)).called(1);
    });

    test('sin sesión lanza AuthException', () async {
      await expectLater(
        controller.fetchProfile(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  test('clearError borra el mensaje de error', () async {
    await controller.login('malo', kPassword);
    expect(controller.errorMessage, isNotNull);

    controller.clearError();

    expect(controller.errorMessage, isNull);
  });
}
