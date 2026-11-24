import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'controllers/auth_controller.dart';
import 'services/auth_service.dart';
import 'services/fake_backend.dart';
import 'services/http_auth_service.dart';

/// URL de la API real. Se pasa al ejecutar:
///   flutter run --dart-define=API_URL=https://mi-api.com
/// Si no se indica, se usa la API simulada (FakeBackend).
const String apiUrl = String.fromEnvironment('API_URL');

void main() {
  runApp(GravityApp(controller: AuthController(_createService())));
}

AuthService _createService() {
  if (apiUrl.isNotEmpty) {
    return HttpAuthService(client: http.Client(), baseUrl: apiUrl);
  }
  final backend = FakeBackend();
  return HttpAuthService(client: backend.client, baseUrl: FakeBackend.baseUrl);
}
