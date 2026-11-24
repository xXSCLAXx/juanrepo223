// PRUEBAS DE WIDGETS: pantalla de registro.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/app.dart';
import 'package:flutter23/controllers/auth_controller.dart';
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

  Future<void> abrirRegistro(WidgetTester tester) =>
      pumpGravityApp(tester, controller, initialRoute: AppRoutes.register);

  Future<void> llenar(
    WidgetTester tester, {
    String name = kNewName,
    String email = kNewEmail,
    String password = kNewPassword,
    String? confirm,
  }) async {
    await tester.enterText(find.byKey(RegisterKeys.name), name);
    await tester.enterText(find.byKey(RegisterKeys.email), email);
    await tester.enterText(find.byKey(RegisterKeys.password), password);
    await tester.enterText(find.byKey(RegisterKeys.confirm), confirm ?? password);
  }

  Future<void> enviar(WidgetTester tester) async {
    await tapVisible(tester, find.byKey(RegisterKeys.submit));
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los 4 campos y el botón', (tester) async {
    await abrirRegistro(tester);

    expect(find.byKey(RegisterKeys.name), findsOneWidget);
    expect(find.byKey(RegisterKeys.email), findsOneWidget);
    expect(find.byKey(RegisterKeys.password), findsOneWidget);
    expect(find.byKey(RegisterKeys.confirm), findsOneWidget);
    expect(find.byKey(RegisterKeys.submit), findsOneWidget);
  });

  testWidgets('enviar vacío muestra un error por campo', (tester) async {
    await abrirRegistro(tester);

    await enviar(tester);

    expect(find.text(ValidationMessages.nameRequired), findsOneWidget);
    expect(find.text(ValidationMessages.emailRequired), findsOneWidget);
    expect(find.text(ValidationMessages.passwordRequired), findsOneWidget);
    expect(find.text(ValidationMessages.confirmRequired), findsOneWidget);
    verifyNever(() => service.register(any(), any(), any()));
  });

  testWidgets('contraseña débil muestra la regla que falta', (tester) async {
    await abrirRegistro(tester);

    await llenar(tester, password: 'Segura123');
    await enviar(tester);

    expect(find.text(ValidationMessages.passwordSymbol), findsOneWidget);
  });

  testWidgets('contraseñas distintas muestran error', (tester) async {
    await abrirRegistro(tester);

    await llenar(tester, confirm: 'Distinta123!');
    await enviar(tester);

    expect(find.text(ValidationMessages.passwordsDontMatch), findsOneWidget);
  });

  testWidgets('registro exitoso navega a Inicio', (tester) async {
    when(() => service.register(any(), any(), any()))
        .thenAnswer((_) async => kNewSession);
    await abrirRegistro(tester);

    await llenar(tester);
    await enviar(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hola, $kNewName'), findsOneWidget);
    verify(() => service.register(kNewName, kNewEmail, kNewPassword)).called(1);
  });

  testWidgets('correo ya registrado muestra el banner de error', (tester) async {
    when(() => service.register(any(), any(), any()))
        .thenThrow(const ConflictException('El correo ya está registrado'));
    await abrirRegistro(tester);

    await llenar(tester);
    await enviar(tester);

    expect(find.byKey(RegisterKeys.error), findsOneWidget);
    expect(find.text(AuthMessages.emailAlreadyRegistered), findsOneWidget);
  });

  testWidgets('"Ya tengo cuenta" vuelve al login', (tester) async {
    await abrirRegistro(tester);

    await tapVisible(tester, find.byKey(RegisterKeys.goLogin));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RegisterScreen), findsNothing);
  });
}
