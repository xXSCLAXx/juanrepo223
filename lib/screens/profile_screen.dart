import 'package:flutter/material.dart';

import '../controllers/auth_scope.dart';
import '../models/user.dart';
import '../services/api_exceptions.dart';
import '../widgets/error_banner.dart';
import '../widgets/user_avatar.dart';

abstract final class ProfileKeys {
  static const loading = Key('profile_loading');
  static const error = Key('profile_error');
  static const retry = Key('profile_retry');
  static const name = Key('profile_name');
  static const email = Key('profile_email');
  static const id = Key('profile_id');
}

/// Consulta GET /users/me y muestra los datos del usuario.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<User>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AuthScope.read(context).fetchProfile();
  }

  void _retry() {
    final future = AuthScope.read(context).fetchProfile();
    setState(() {
      _future = future;
    });
  }

  String _messageFor(Object? error) {
    if (error is NetworkException) {
      return 'Sin conexión. No se pudo cargar el perfil.';
    }
    if (error is AuthException) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión.';
    }
    return 'No se pudo cargar el perfil.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: FutureBuilder<User>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(key: ProfileKeys.loading),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ErrorBanner(
                      key: ProfileKeys.error,
                      message: _messageFor(snapshot.error),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: ProfileKeys.retry,
                      onPressed: _retry,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          final user = snapshot.requireData;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: UserAvatar(initials: user.initials, radius: 48)),
              const SizedBox(height: 24),
              ListTile(
                key: ProfileKeys.name,
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Nombre'),
                subtitle: Text(user.name),
              ),
              ListTile(
                key: ProfileKeys.email,
                leading: const Icon(Icons.email_outlined),
                title: const Text('Correo'),
                subtitle: Text(user.email),
              ),
              ListTile(
                key: ProfileKeys.id,
                leading: const Icon(Icons.tag),
                title: const Text('ID de usuario'),
                subtitle: Text(user.id),
              ),
            ],
          );
        },
      ),
    );
  }
}
