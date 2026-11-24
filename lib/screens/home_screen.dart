import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../controllers/auth_scope.dart';
import '../widgets/user_avatar.dart';

abstract final class HomeKeys {
  static const greeting = Key('home_greeting');
  static const email = Key('home_email');
  static const goProfile = Key('go_profile');
  static const logout = Key('logout_button');
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout(BuildContext context) {
    final auth = AuthScope.read(context);
    // Navegamos primero para no mostrar la pantalla vacía, luego avisamos a la API.
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    unawaited(auth.logout());
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sesión no iniciada')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            key: HomeKeys.logout,
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: UserAvatar(initials: user.initials)),
          const SizedBox(height: 16),
          Text(
            'Hola, ${user.name}',
            key: HomeKeys.greeting,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(user.email, key: HomeKeys.email, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Card(
            child: ListTile(
              key: HomeKeys.goProfile,
              leading: const Icon(Icons.person),
              title: const Text('Mi perfil'),
              subtitle: const Text('Ver la información de mi cuenta'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            ),
          ),
        ],
      ),
    );
  }
}
