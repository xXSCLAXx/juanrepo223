// Funciones de ayuda para las pruebas de widgets.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/app.dart';
import 'package:flutter23/controllers/auth_controller.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';
import 'test_data.dart';

/// Monta la app completa con el controlador indicado.
Future<void> pumpGravityApp(
  WidgetTester tester,
  AuthController controller, {
  String initialRoute = AppRoutes.login,
}) async {
  await tester.pumpWidget(
    GravityApp(controller: controller, initialRoute: initialRoute),
  );
  await tester.pumpAndSettle();
}

/// Hace scroll hasta el widget (si está fuera de pantalla) y lo toca.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

/// Deja el controlador con sesión iniciada usando el mock.
Future<void> signInWithMock(
  MockAuthService service,
  AuthController controller,
) async {
  when(() => service.login(any(), any())).thenAnswer((_) async => kSession);
  await controller.login(kEmail, kPassword);
}
