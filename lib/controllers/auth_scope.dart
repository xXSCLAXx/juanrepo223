import 'package:flutter/widgets.dart';

import 'auth_controller.dart';

/// Hace disponible el [AuthController] a todas las pantallas sin paquetes
/// externos (InheritedNotifier es parte de Flutter).
///
/// - `AuthScope.of(context)`  -> obtiene el controlador y redibuja al cambiar.
/// - `AuthScope.read(context)` -> lo obtiene sin suscribirse (para callbacks).
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No se encontró un AuthScope en el árbol de widgets');
    return scope!.notifier!;
  }

  static AuthController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No se encontró un AuthScope en el árbol de widgets');
    return scope!.notifier!;
  }
}
