# GRAVITY APP

Aplicación Flutter de registro, inicio de sesión y perfil de usuario, construida con
arquitectura por capas y un proceso de testing profesional.

## Funcionalidades

- Registro de usuarios con validación de nombre, correo y contraseña segura
- Inicio y cierre de sesión con bloqueo tras 5 intentos fallidos
- Perfil consumido desde una API REST (`GET /users/me`)
- API simulada incluida (`FakeBackend`), o una real con `--dart-define=API_URL=...`

Usuario de prueba: `demo@gravity.com` / `Gravity123!`

## Estructura

```
lib/
  models/        User, AuthSession
  services/      AuthService, HttpAuthService (REST), FakeBackend, excepciones
  controllers/   AuthController (reglas de negocio), AuthScope
  screens/       Login, Registro, Inicio, Perfil
  widgets/       AppTextField, PrimaryButton, ErrorBanner, UserAvatar
  validators/    Validaciones de formularios
test/
  unit/          Pruebas unitarias
  widget/        Pruebas de widgets
  mocks/         Mocks (mocktail), datos y helpers
  security/      Pruebas de seguridad
  performance/   Pruebas de rendimiento
  regression/    Pruebas de regresión
integration_test/  Pruebas de integración (end-to-end)
tool/            Prueba de carga y reporte de cobertura
docs/            Guía paso a paso y matriz de pruebas
```

## Comandos

```powershell
flutter pub get
flutter run -d windows
flutter analyze
flutter test
flutter test integration_test -d windows
dart run tool/load_test.dart
flutter test --coverage
dart run tool/coverage_report.dart
```

Guía completa: [`docs/GUIA_PASO_A_PASO.txt`](docs/GUIA_PASO_A_PASO.txt)
Matriz de pruebas: [`docs/MATRIZ_DE_PRUEBAS.csv`](docs/MATRIZ_DE_PRUEBAS.csv)
