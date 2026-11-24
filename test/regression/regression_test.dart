// PRUEBAS DE REGRESIÓN
//
// Cada prueba corresponde a un error (bug) que ya se corrigió.
// Si alguien vuelve a introducir el error, la prueba falla y lo detecta.
// Regla del equipo: TODO bug corregido debe agregar aquí su prueba.
//
// Además, ejecutar `flutter test` completo antes de cada commit/PR es en sí una
// prueba de regresión de toda la app (lo hace el pipeline de GitHub Actions).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/app.dart';
import 'package:flutter23/controllers/auth_controller.dart';
import 'package:flutter23/models/auth_session.dart';
import 'package:flutter23/screens/home_screen.dart';
import 'package:flutter23/screens/login_screen.dart';
import 'package:flutter23/services/api_exceptions.dart';
import 'package:flutter23/validators/validators.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mocks.dart';
import '../mocks/test_data.dart';
import '../mocks/test_helpers.dart';

void main() {
  late MockAuthService service;
  late AuthController controller;

  setUp(() {
    service = MockAuthService();
    controller = AuthController(service);
  });

  test('REG-001 un correo con espacios y mayúsculas permite iniciar sesión',
      () async {
    // Bug: "  Demo@Gravity.com " se enviaba tal cual y el servidor respondía 401.
    when(() => service.login(any(), any())).thenAnswer((_) async => kSession);

    final ok = await controller.login('  Demo@Gravity.com ', kPassword);

    expect(ok, isTrue);
    verify(() => service.login('demo@gravity.com', kPassword)).called(1);
  });

  testWidgets('REG-002 doble toque en "Ingresar" envía UNA sola petición',
      (tester) async {
    // Bug: tocar dos veces rápido creaba dos sesiones en el servidor.
    final completer = Completer<AuthSession>();
    when(() => service.login(any(), any())).thenAnswer((_) => completer.future);
    await pumpGravityApp(tester, controller);
    await tester.enterText(find.byKey(LoginKeys.email), kEmail);
    await tester.enterText(find.byKey(LoginKeys.password), kPassword);

    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.tap(find.byKey(LoginKeys.submit), warnIfMissed: false);
    await tester.pump();
    completer.complete(kSession);
    await tester.pumpAndSettle();

    verify(() => service.login(any(), any())).called(1);
  });

  testWidgets('REG-003 después de cerrar sesión no se puede volver atrás a Inicio',
      (tester) async {
    // Bug: el botón "atrás" de Android regresaba a la pantalla de Inicio.
    await signInWithMock(service, controller);
    when(() => service.logout(any())).thenAnswer((_) async {});
    await pumpGravityApp(tester, controller, initialRoute: AppRoutes.home);

    await tester.tap(find.byKey(HomeKeys.logout));
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(navigator.canPop(), isFalse);
  });

  test('REG-004 el error anterior se borra después de un login exitoso',
      () async {
    // Bug: el banner rojo seguía visible en la siguiente sesión.
    when(() => service.login(any(), any()))
        .thenThrow(const AuthException('Credenciales inválidas'));
    await controller.login(kEmail, 'Incorrecta1!');
    expect(controller.errorMessage, isNotNull);

    when(() => service.login(any(), any())).thenAnswer((_) async => kSession);
    await controller.login(kEmail, kPassword);

    expect(controller.errorMessage, isNull);
  });

  test('REG-005 una contraseña de exactamente 64 caracteres es aceptada', () {
    // Bug: se usaba "< 64" en vez de "<= 64" y se rechazaba el valor límite.
    final pass = 'Aa1!${'b' * 60}';
    expect(pass.length, Validators.passwordMaxLength);
    expect(Validators.password(pass), isNull);
  });

  testWidgets('REG-006 ir a Registro borra el error del Login', (tester) async {
    // Bug: el error del login aparecía también en la pantalla de registro.
    when(() => service.login(any(), any()))
        .thenThrow(const AuthException('Credenciales inválidas'));
    await pumpGravityApp(tester, controller);
    await tester.enterText(find.byKey(LoginKeys.email), kEmail);
    await tester.enterText(find.byKey(LoginKeys.password), 'Incorrecta1!');
    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pumpAndSettle();
    expect(find.text(AuthMessages.invalidCredentials), findsOneWidget);

    await tester.tap(find.byKey(LoginKeys.goRegister));
    await tester.pumpAndSettle();

    expect(find.text(AuthMessages.invalidCredentials), findsNothing);
  });
}
