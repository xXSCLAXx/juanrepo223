import 'package:flutter/material.dart';

import 'controllers/auth_controller.dart';
import 'controllers/auth_scope.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';

/// Rutas con nombre de la aplicación.
abstract final class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
}

/// Widget raíz. Recibe el controlador por constructor para poder
/// inyectar uno con mocks en las pruebas.
class GravityApp extends StatelessWidget {
  const GravityApp({
    super.key,
    required this.controller,
    this.initialRoute = AppRoutes.login,
  });

  final AuthController controller;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: controller,
      child: MaterialApp(
        title: 'GRAVITY APP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        initialRoute: initialRoute,
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.home: (_) => const HomeScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
        },
      ),
    );
  }
}
