// PRUEBAS DE WIDGETS: pantalla de inicio, perfil (consumo de API) y logout.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/app.dart';
import 'package:flutter23/controllers/auth_controller.dart';
import 'package:flutter23/models/user.dart';
import 'package:flutter23/screens/home_screen.dart';
import 'package:flutter23/screens/login_screen.dart';
import 'package:flutter23/screens/profile_screen.dart';
import 'package:flutter23/services/api_exceptions.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mocks.dart';
import '../mocks/test_data.dart';
import '../mocks/test_helpers.dart';

void main() {
  late MockAuthService service;
  late AuthController controller;

  setUp(() async {
    service = MockAuthService();
    controller = AuthController(service);
    await signInWithMock(service, controller); // empieza con sesión iniciada
  });

  Future<void> abrirInicio(WidgetTester tester) =>
      pumpGravityApp(tester, controller, initialRoute: AppRoutes.home);

  group('Inicio', () {
    testWidgets('muestra saludo, correo e iniciales', (tester) async {
      await abrirInicio(tester);

      expect(find.text('Hola, Usuario Demo'), findsOneWidget);
      expect(find.text(kEmail), findsOneWidget);
      expect(find.text('UD'), findsOneWidget);
    });

    testWidgets('cerrar sesión vuelve al login y avisa a la API',
        (tester) async {
      when(() => service.logout(any())).thenAnswer((_) async {});
      await abrirInicio(tester);

      await tester.tap(find.byKey(HomeKeys.logout));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(controller.isAuthenticated, isFalse);
      verify(() => service.logout(kSession.token)).called(1);
    });
  });

  group('Perfil', () {
    testWidgets('muestra indicador de carga mientras consulta la API',
        (tester) async {
      final completer = Completer<User>();
      when(() => service.getProfile(any())).thenAnswer((_) => completer.future);
      await tester.pumpWidget(
        GravityApp(
          controller: controller,
          initialRoute: AppRoutes.profile,
        ),
      );

      expect(find.byKey(ProfileKeys.loading), findsOneWidget);

      completer.complete(kUser);
      await tester.pumpAndSettle();
      expect(find.byKey(ProfileKeys.loading), findsNothing);
    });

    testWidgets('muestra los datos devueltos por la API', (tester) async {
      when(() => service.getProfile(any())).thenAnswer((_) async => kUser);
      await abrirInicio(tester);

      await tester.tap(find.byKey(HomeKeys.goProfile));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Usuario Demo'), findsOneWidget);
      expect(find.text(kEmail), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      verify(() => service.getProfile(kSession.token)).called(1);
    });

    testWidgets('error de conexión muestra mensaje y "Reintentar" funciona',
        (tester) async {
      when(() => service.getProfile(any()))
          .thenThrow(const NetworkException('Sin conexión'));
      await abrirInicio(tester);

      await tester.tap(find.byKey(HomeKeys.goProfile));
      await tester.pumpAndSettle();

      expect(find.byKey(ProfileKeys.error), findsOneWidget);
      expect(find.text('Sin conexión. No se pudo cargar el perfil.'),
          findsOneWidget);

      // La red vuelve: ahora la API responde bien.
      when(() => service.getProfile(any())).thenAnswer((_) async => kUser);
      await tester.tap(find.byKey(ProfileKeys.retry));
      await tester.pumpAndSettle();

      expect(find.byKey(ProfileKeys.error), findsNothing);
      expect(find.text('Usuario Demo'), findsOneWidget);
    });

    testWidgets('token expirado (401) pide volver a iniciar sesión',
        (tester) async {
      when(() => service.getProfile(any()))
          .thenThrow(const AuthException('Token inválido'));
      await abrirInicio(tester);

      await tester.tap(find.byKey(HomeKeys.goProfile));
      await tester.pumpAndSettle();

      expect(find.text('Tu sesión expiró. Vuelve a iniciar sesión.'),
          findsOneWidget);
    });
  });
}
