// PRUEBAS DE WIDGETS: componentes reutilizables (lib/widgets) por separado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/widgets/app_text_field.dart';
import 'package:flutter23/widgets/error_banner.dart';
import 'package:flutter23/widgets/primary_button.dart';
import 'package:flutter23/widgets/user_avatar.dart';

/// Los componentes Material necesitan un MaterialApp alrededor.
Widget envolver(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PrimaryButton', () {
    testWidgets('muestra el texto y ejecuta onPressed', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        envolver(PrimaryButton(label: 'Enviar', onPressed: () => toques++)),
      );

      await tester.tap(find.text('Enviar'));

      expect(toques, 1);
    });

    testWidgets('en carga muestra spinner y no responde', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        envolver(
          PrimaryButton(
            label: 'Enviar',
            isLoading: true,
            onPressed: () => toques++,
          ),
        ),
      );

      expect(find.text('Enviar'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(PrimaryButton));
      expect(toques, 0);
    });
  });

  testWidgets('ErrorBanner muestra el mensaje y el icono', (tester) async {
    await tester.pumpWidget(envolver(const ErrorBanner(message: 'Algo falló')));

    expect(find.text('Algo falló'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  group('AppTextField', () {
    testWidgets('muestra el error del validador al validar el formulario',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        envolver(
          Form(
            key: formKey,
            child: AppTextField(
              controller: controller,
              label: 'Nombre',
              validator: (v) => (v ?? '').isEmpty ? 'Requerido' : null,
            ),
          ),
        ),
      );

      expect(find.text('Nombre'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Requerido'), findsOneWidget);

      await tester.enterText(find.byType(AppTextField), 'Ana');
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('Requerido'), findsNothing);
    });

    testWidgets('un campo normal no tiene botón de ver contraseña',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        envolver(AppTextField(controller: controller, label: 'Correo')),
      );

      expect(find.byTooltip('Mostrar contraseña'), findsNothing);
    });
  });

  group('UserAvatar', () {
    testWidgets('muestra las iniciales', (tester) async {
      await tester.pumpWidget(envolver(const UserAvatar(initials: 'AP')));
      expect(find.text('AP'), findsOneWidget);
    });

    testWidgets('sin iniciales muestra "?"', (tester) async {
      await tester.pumpWidget(envolver(const UserAvatar(initials: '')));
      expect(find.text('?'), findsOneWidget);
    });
  });
}
