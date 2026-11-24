// Datos de prueba reutilizables (fixtures).
import 'package:flutter23/models/auth_session.dart';
import 'package:flutter23/models/user.dart';

const String kEmail = 'demo@gravity.com';
const String kPassword = 'Gravity123!';
const User kUser = User(id: '1', name: 'Usuario Demo', email: kEmail);
const AuthSession kSession =
    AuthSession(user: kUser, token: 'token-de-prueba-123');

const String kNewName = 'Ana Pérez';
const String kNewEmail = 'ana@gravity.com';
const String kNewPassword = 'Segura123!';
const User kNewUser = User(id: '2', name: kNewName, email: kNewEmail);
const AuthSession kNewSession =
    AuthSession(user: kNewUser, token: 'token-ana-456');

/// JSON tal como lo devolvería la API.
const Map<String, dynamic> kUserJson = {
  'id': '1',
  'name': 'Usuario Demo',
  'email': kEmail,
};
const Map<String, dynamic> kSessionJson = {
  'token': 'token-de-prueba-123',
  'user': kUserJson,
};
