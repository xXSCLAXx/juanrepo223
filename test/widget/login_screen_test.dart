// PRUEBAS DE WIDGETS: pantalla de inicio de sesión.
// Se monta la app real con un AuthService simulado (mocktail).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/controllers/auth_controller.dart';
import 'package:flutter23/models/auth_session.dart';
import 'package:flutter23/screens/home_screen.dart';
import 'package:flutter23/screens/login_screen.dart';
import 'package:flutter23/screens/register_screen.dart';
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

  Future<void> llenarFormulario(
    WidgetTester tester, {
    String email = kEmail,
    String password = kPassword,
  }) async {
    await tester.enterText(find.byKey(LoginKeys.email), email);
    await tester.enterText(find.byKey(LoginKeys.password), password);
  }

  testWidgets('muestra todos los elementos del formulario', (tester) async {
    await pumpGravityApp(tester, controller);

    expect(find.text('GRAVITY APP'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.byKey(LoginKeys.email), findsOneWidget);
    expect(find.byKey(LoginKeys.password), findsOneWidget);
    expect(find.byKey(LoginKeys.submit), findsOneWidget);
    expect(find.byKey(LoginKeys.goRegister), findsOneWidget);
    expect(find.byKey(LoginKeys.error), findsNothing);
  });

  testWidgets('enviar vacío muestra errores y NO llama a la API', (tester) async {
    await pumpGravityApp(tester, controller);

    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pump();

    expect(find.text(ValidationMessages.emailRequired), findsOneWidget);
    expect(find.text(ValidationMessages.passwordRequired), findsOneWidget);
    verifyNever(() => service.login(any(), any()));
  });

  testWidgets('correo con formato inválido muestra error', (tester) async {
    await pumpGravityApp(tester, controller);

    await llenarFormulario(tester, email: 'correo-malo');
    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pump();

    expect(find.text(ValidationMessages.emailInvalid), findsOneWidget);
  });

  testWidgets('el icono del ojo muestra y oculta la contraseña', (tester) async {
    await pumpGravityApp(tester, controller);
    final campo = find.descendant(
      of: find.byKey(LoginKeys.password),
      matching: find.byType(EditableText),
    );

    expect(tester.widget<EditableText>(campo).obscureText, isTrue);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();

    expect(tester.widget<EditableText>(campo).obscureText, isFalse);
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
  });

  testWidgets('muestra indicador de carga y deshabilita el botón', (tester) async {
    final completer = Completer<AuthSession>();
    when(() => service.login(any(), any())).thenAnswer((_) => completer.future);
    await pumpGravityApp(tester, controller);

    await llenarFormulario(tester);
    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pump();

    final boton = find.descendant(
      of: find.byKey(LoginKeys.submit),
      matching: find.byType(FilledButton),
    );
    expect(
      find.descendant(
        of: find.byKey(LoginKeys.submit),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(boton).onPressed, isNull);

    completer.complete(kSession);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('credenciales incorrectas muestran el banner de error',
      (tester) async {
    when(() => service.login(any(), any()))
        .thenThrow(const AuthException('Credenciales inválidas'));
    await pumpGravityApp(tester, controller);

    await llenarFormulario(tester, password: 'Incorrecta1!');
    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pumpAndSettle();

    expect(find.byKey(LoginKeys.error), findsOneWidget);
    expect(find.text(AuthMessages.invalidCredentials), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget); // no navegó
  });

  testWidgets('sin conexión muestra el mensaje correspondiente', (tester) async {
    when(() => service.login(any(), any()))
        .thenThrow(const NetworkException('Sin conexión'));
    await pumpGravityApp(tester, controller);

    await llenarFormulario(tester);
    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pumpAndSettle();

    expect(find.text(AuthMessages.noConnection), findsOneWidget);
  });

  testWidgets('login exitoso navega a Inicio y saluda al usuario',
      (tester) async {
    when(() => service.login(any(), any())).thenAnswer((_) async => kSession);
    await pumpGravityApp(tester, controller);

    await llenarFormulario(tester);
    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hola, Usuario Demo'), findsOneWidget);
  });

  testWidgets('"Regístrate" navega a la pantalla de registro', (tester) async {
    await pumpGravityApp(tester, controller);

    await tester.tap(find.byKey(LoginKeys.goRegister));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
