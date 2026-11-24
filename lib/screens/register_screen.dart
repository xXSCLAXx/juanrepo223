import 'package:flutter/material.dart';

import '../app.dart';
import '../controllers/auth_scope.dart';
import '../validators/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';

abstract final class RegisterKeys {
  static const name = Key('register_name');
  static const email = Key('register_email');
  static const password = Key('register_password');
  static const confirm = Key('register_confirm');
  static const submit = Key('register_button');
  static const error = Key('register_error');
  static const goLogin = Key('go_login');
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = AuthScope.read(context);
    final ok = await auth.register(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      confirmPassword: _confirmCtrl.text,
    );
    if (!mounted || !ok) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  void _backToLogin() {
    AuthScope.read(context).clearError();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final error = auth.errorMessage;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
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
                    if (error != null) ...[
                      ErrorBanner(key: RegisterKeys.error, message: error),
                      const SizedBox(height: 16),
                    ],
                    AppTextField(
                      key: RegisterKeys.name,
                      controller: _nameCtrl,
                      label: 'Nombre completo',
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      key: RegisterKeys.email,
                      controller: _emailCtrl,
                      label: 'Correo electrónico',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      key: RegisterKeys.password,
                      controller: _passwordCtrl,
                      label: 'Contraseña',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      helperText:
                          'Mínimo 8 caracteres, con mayúscula, minúscula, número y símbolo',
                      textInputAction: TextInputAction.next,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      key: RegisterKeys.confirm,
                      controller: _confirmCtrl,
                      label: 'Confirmar contraseña',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) =>
                          Validators.confirmPassword(v, _passwordCtrl.text),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      key: RegisterKeys.submit,
                      label: 'Crear cuenta',
                      isLoading: auth.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      key: RegisterKeys.goLogin,
                      onPressed: auth.isLoading ? null : _backToLogin,
                      child: const Text('Ya tengo cuenta. Iniciar sesión'),
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
