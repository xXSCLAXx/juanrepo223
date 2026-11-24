import 'package:flutter/material.dart';

import '../app.dart';
import '../controllers/auth_scope.dart';
import '../validators/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';

/// Keys usadas por las pruebas para encontrar los widgets.
abstract final class LoginKeys {
  static const email = Key('login_email');
  static const password = Key('login_password');
  static const submit = Key('login_button');
  static const error = Key('login_error');
  static const goRegister = Key('go_register');
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = AuthScope.read(context);
    final ok = await auth.login(_emailCtrl.text, _passwordCtrl.text);
    if (!mounted || !ok) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  void _goToRegister() {
    AuthScope.read(context).clearError();
    Navigator.of(context).pushNamed(AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final error = auth.errorMessage;

    return Scaffold(
      appBar: AppBar(title: const Text('GRAVITY APP')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Iniciar sesión',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    if (error != null) ...[
                      ErrorBanner(key: LoginKeys.error, message: error),
                      const SizedBox(height: 16),
                    ],
                    AppTextField(
                      key: LoginKeys.email,
                      controller: _emailCtrl,
                      label: 'Correo electrónico',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      key: LoginKeys.password,
                      controller: _passwordCtrl,
                      label: 'Contraseña',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) => Validators.notEmpty(
                        v,
                        message: ValidationMessages.passwordRequired,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      key: LoginKeys.submit,
                      label: 'Ingresar',
                      isLoading: auth.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      key: LoginKeys.goRegister,
                      onPressed: auth.isLoading ? null : _goToRegister,
                      child: const Text('¿No tienes cuenta? Regístrate'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
