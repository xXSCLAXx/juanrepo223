// PRUEBAS DE RENDIMIENTO (micro-benchmarks)
//
// Miden con Stopwatch que operaciones críticas se mantengan rápidas.
// Los límites son AMPLIOS a propósito: el modo de prueba (debug/JIT) es más lento
// que la app compilada en release. Su objetivo es detectar degradaciones graves
// (por ejemplo, una validación que pasa de 1 ms a 2 segundos).
//
// Para medir la app real (FPS, memoria, jank) usa:
//   flutter run --profile   + Flutter DevTools (pestaña Performance)
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/app.dart';
import 'package:flutter23/controllers/auth_controller.dart';
import 'package:flutter23/models/user.dart';
import 'package:flutter23/services/fake_backend.dart';
import 'package:flutter23/services/http_auth_service.dart';
import 'package:flutter23/validators/validators.dart';

import '../mocks/mocks.dart';

/// Ejecuta [accion] y devuelve los milisegundos que tardó.
Future<int> medir(Future<void> Function() accion) async {
  final reloj = Stopwatch()..start();
  await accion();
  reloj.stop();
  return reloj.elapsedMilliseconds;
}

void main() {
  test('PERF-01 10.000 validaciones de correo en menos de 500 ms', () async {
    final ms = await medir(() async {
      for (var i = 0; i < 10000; i++) {
        Validators.email('usuario$i@gravity.com');
      }
    });
    // ignore: avoid_print
    print('PERF-01: 10.000 validaciones de correo en $ms ms');
    expect(ms, lessThan(500));
  });

  test('PERF-02 10.000 validaciones de contraseña en menos de 500 ms', () async {
    final ms = await medir(() async {
      for (var i = 0; i < 10000; i++) {
        Validators.password('Gravity$i!');
      }
    });
    // ignore: avoid_print
    print('PERF-02: 10.000 validaciones de contraseña en $ms ms');
    expect(ms, lessThan(500));
  });

  test('PERF-03 convertir 5.000 usuarios desde JSON en menos de 500 ms',
      () async {
    final jsonText = jsonEncode([
      for (var i = 0; i < 5000; i++)
        {'id': '$i', 'name': 'Usuario $i', 'email': 'u$i@gravity.com'},
    ]);

    final ms = await medir(() async {
      final lista = (jsonDecode(jsonText) as List)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(lista, hasLength(5000));
    });
    // ignore: avoid_print
    print('PERF-03: 5.000 usuarios parseados en $ms ms');
    expect(ms, lessThan(500));
  });

  test('PERF-04 200 logins seguidos contra la API simulada en menos de 3 s',
      () async {
    final backend = FakeBackend(latency: Duration.zero);
    final controller = AuthController(
      HttpAuthService(client: backend.client, baseUrl: FakeBackend.baseUrl),
    );

    final ms = await medir(() async {
      for (var i = 0; i < 200; i++) {
        final ok = await controller.login(
          FakeBackend.demoEmail,
          FakeBackend.demoPassword,
        );
        expect(ok, isTrue);
        await controller.logout();
      }
    });
    // ignore: avoid_print
    print('PERF-04: 200 ciclos login/logout en $ms ms');
    expect(ms, lessThan(3000));
  });

  testWidgets('PERF-05 la pantalla de login se construye en menos de 1,5 s',
      (tester) async {
    final controller = AuthController(MockAuthService());
    final reloj = Stopwatch()..start();

    await tester.pumpWidget(GravityApp(controller: controller));
    await tester.pumpAndSettle();

    reloj.stop();
    // ignore: avoid_print
    print('PERF-05: primer dibujo del login en ${reloj.elapsedMilliseconds} ms');
    expect(reloj.elapsedMilliseconds, lessThan(1500));
  });
}
