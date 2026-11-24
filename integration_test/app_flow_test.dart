// PRUEBAS DE INTEGRACIÓN (end-to-end).
//
// Ejecutan la app COMPLETA en un dispositivo real, emulador o escritorio
// (Windows), con la API simulada (FakeBackend) y el HttpAuthService real.
// No hay mocks: se prueba todo el sistema junto.
//
// Ejecutar:  flutter test integration_test -d windows
//            flutter test integration_test -d emulator-5554
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/app.dart';
import 'package:flutter23/controllers/auth_controller.dart';
import 'package:flutter23/screens/home_screen.dart';
import 'package:flutter23/screens/login_screen.dart';
import 'package:flutter23/screens/profile_screen.dart';
import 'package:flutter23/screens/register_screen.dart';
import 'package:flutter23/services/fake_backend.dart';
import 'package:flutter23/services/http_auth_service.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Arranca la app con un backend simulado nuevo (datos limpios en cada prueba).
  Future<void> iniciarApp(WidgetTester tester) async {
    final backend = FakeBackend(latency: const Duration(milliseconds: 300));
    final service = HttpAuthService(
      client: backend.client,
      baseUrl: FakeBackend.baseUrl,
    );
    await tester.pumpWidget(GravityApp(controller: AuthController(service)));
    await tester.pumpAndSettle();
  }

  Future<void> escribir(WidgetTester tester, Key key, String texto) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.enterText(find.byKey(key), texto);
    await tester.pump();
  }

  Future<void> tocar(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Future<void> iniciarSesion(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await escribir(tester, LoginKeys.email, email);
    await escribir(tester, LoginKeys.password, password);
    await tocar(tester, LoginKeys.submit);
  }

  Future<void> registrarse(
    WidgetTester tester, {
    required String nombre,
    required String email,
    required String password,
  }) async {
    await tocar(tester, LoginKeys.goRegister);
    expect(find.byType(RegisterScreen), findsOneWidget);
    await escribir(tester, RegisterKeys.name, nombre);
    await escribir(tester, RegisterKeys.email, email);
    await escribir(tester, RegisterKeys.password, password);
    await escribir(tester, RegisterKeys.confirm, password);
    await tocar(tester, RegisterKeys.submit);
  }

  group('GRAVITY APP - flujos completos', () {
    testWidgets('IT-01 Registro de un usuario nuevo lleva a Inicio',
        (tester) async {
      await iniciarApp(tester);

      await registrarse(
        tester,
        nombre: 'Ana Pérez',
        email: 'ana@gravity.com',
        password: 'Segura123!',
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Hola, Ana Pérez'), findsOneWidget);
    });

    testWidgets('IT-02 Registro con correo existente muestra error',
        (tester) async {
      await iniciarApp(tester);

      await registrarse(
        tester,
        nombre: 'Otro Usuario',
        email: FakeBackend.demoEmail,
        password: 'Segura123!',
      );

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text(AuthMessages.emailAlreadyRegistered), findsOneWidget);
    });

    testWidgets('IT-03 Login con usuario demo', (tester) async {
      await iniciarApp(tester);

      await iniciarSesion(
        tester,
        FakeBackend.demoEmail,
        FakeBackend.demoPassword,
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Hola, Usuario Demo'), findsOneWidget);
    });

    testWidgets('IT-04 Login con contraseña incorrecta muestra error',
        (tester) async {
      await iniciarApp(tester);

      await iniciarSesion(tester, FakeBackend.demoEmail, 'Incorrecta1!');

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(AuthMessages.invalidCredentials), findsOneWidget);
    });

    testWidgets('IT-05 Navegación: Inicio -> Perfil -> atrás -> logout',
        (tester) async {
      await iniciarApp(tester);
      await iniciarSesion(
        tester,
        FakeBackend.demoEmail,
        FakeBackend.demoPassword,
      );

      await tocar(tester, HomeKeys.goProfile);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Usuario Demo'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      await tocar(tester, HomeKeys.logout);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets(
        'IT-06 Flujo completo: registro -> perfil -> logout -> login de nuevo',
        (tester) async {
      await iniciarApp(tester);

      // 1. Registro
      await registrarse(
        tester,
        nombre: 'Luis Gómez',
        email: 'luis@gravity.com',
        password: 'Gravity2026!',
      );
      expect(find.text('Hola, Luis Gómez'), findsOneWidget);

      // 2. Perfil (consume GET /users/me)
      await tocar(tester, HomeKeys.goProfile);
      expect(find.text('luis@gravity.com'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 3. Cerrar sesión
      await tocar(tester, HomeKeys.logout);
      expect(find.byType(LoginScreen), findsOneWidget);

      // 4. Volver a entrar con la cuenta recién creada
      await iniciarSesion(tester, 'luis@gravity.com', 'Gravity2026!');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Hola, Luis Gómez'), findsOneWidget);
    });
  });
}
