// PRUEBA DE CARGA SOBRE LA API
//
// Envía muchas peticiones concurrentes a POST /auth/login y mide:
//   - peticiones por segundo (throughput)
//   - latencias: mínima, promedio, p50, p95, p99 y máxima
//   - porcentaje de errores
//
// Uso (desde la carpeta del proyecto):
//   dart run tool/load_test.dart
//   dart run tool/load_test.dart --requests 1000 --concurrency 50
//   dart run tool/load_test.dart --url https://mi-api.com/auth/login
//
// Sin --url levanta un servidor local que simula la API (no necesita internet).
// IMPORTANTE: solo ejecuta pruebas de carga contra APIs PROPIAS o con permiso.
//
// Termina con código 1 si el % de errores supera --max-errors (por defecto 1)
// o si el p95 supera --max-p95 milisegundos (por defecto 500). Así sirve en CI.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final opciones = _leerArgumentos(args);
  final total = int.parse(opciones['requests'] ?? '300');
  final concurrencia = int.parse(opciones['concurrency'] ?? '30');
  final maxP95 = int.parse(opciones['max-p95'] ?? '500');
  final maxErrores = double.parse(opciones['max-errors'] ?? '1');

  HttpServer? servidorLocal;
  final String url;
  if (opciones['url'] != null) {
    url = opciones['url']!;
  } else {
    servidorLocal = await _iniciarServidorSimulado();
    url = 'http://${servidorLocal.address.host}:${servidorLocal.port}/auth/login';
  }

  stdout.writeln('=== PRUEBA DE CARGA - GRAVITY APP ===');
  stdout.writeln('URL:           $url');
  stdout.writeln('Peticiones:    $total');
  stdout.writeln('Concurrencia:  $concurrencia usuarios simultáneos');
  stdout.writeln('Ejecutando...\n');

  final cliente = http.Client();
  final latencias = <int>[];
  final codigos = <String, int>{};
  var exitosas = 0;
  var fallidas = 0;
  var siguiente = 0;

  Future<void> usuarioVirtual() async {
    while (true) {
      final i = siguiente++;
      if (i >= total) return;
      final reloj = Stopwatch()..start();
      String resultado;
      try {
        final respuesta = await cliente
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': 'demo@gravity.com',
                'password': 'Gravity123!',
              }),
            )
            .timeout(const Duration(seconds: 10));
        resultado = '${respuesta.statusCode}';
        if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
          exitosas++;
        } else {
          fallidas++;
        }
      } on Exception catch (e) {
        resultado = e.runtimeType.toString();
        fallidas++;
      }
      reloj.stop();
      latencias.add(reloj.elapsedMilliseconds);
      codigos.update(resultado, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  final relojTotal = Stopwatch()..start();
  await Future.wait(List.generate(concurrencia, (_) => usuarioVirtual()));
  relojTotal.stop();

  cliente.close();
  await servidorLocal?.close(force: true);

  latencias.sort();
  final segundos = relojTotal.elapsedMilliseconds / 1000;
  final porcentajeErrores = fallidas * 100 / total;
  final p95 = _percentil(latencias, 95);
  final promedio = latencias.reduce((a, b) => a + b) / latencias.length;

  stdout.writeln('--- RESULTADOS ---');
  stdout.writeln('Tiempo total:      ${segundos.toStringAsFixed(2)} s');
  stdout.writeln('Throughput:        ${(total / segundos).toStringAsFixed(1)} req/s');
  stdout.writeln('Exitosas:          $exitosas');
  stdout.writeln('Fallidas:          $fallidas (${porcentajeErrores.toStringAsFixed(2)} %)');
  stdout.writeln('Códigos:           $codigos');
  stdout.writeln('Latencia mínima:   ${latencias.first} ms');
  stdout.writeln('Latencia promedio: ${promedio.toStringAsFixed(1)} ms');
  stdout.writeln('Latencia p50:      ${_percentil(latencias, 50)} ms');
  stdout.writeln('Latencia p95:      $p95 ms');
  stdout.writeln('Latencia p99:      ${_percentil(latencias, 99)} ms');
  stdout.writeln('Latencia máxima:   ${latencias.last} ms');

  final aprobado = porcentajeErrores <= maxErrores && p95 <= maxP95;
  stdout.writeln(
    '\nCriterio: errores <= $maxErrores % y p95 <= $maxP95 ms -> '
    '${aprobado ? 'APROBADO' : 'RECHAZADO'}',
  );
  exitCode = aprobado ? 0 : 1;
}

int _percentil(List<int> ordenadas, int p) {
  final indice = ((p / 100) * (ordenadas.length - 1)).round();
  return ordenadas[indice];
}

Map<String, String> _leerArgumentos(List<String> args) {
  final mapa = <String, String>{};
  for (var i = 0; i < args.length - 1; i++) {
    if (args[i].startsWith('--')) {
      mapa[args[i].substring(2)] = args[i + 1];
    }
  }
  return mapa;
}

/// Servidor HTTP local que imita POST /auth/login con 20-80 ms de latencia.
Future<HttpServer> _iniciarServidorSimulado() async {
  final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final random = Random();
  servidor.listen((peticion) async {
    await utf8.decoder.bind(peticion).join();
    await Future<void>.delayed(Duration(milliseconds: 20 + random.nextInt(60)));
    peticion.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'token': 'tok_${random.nextInt(1 << 30)}',
        'user': {'id': '1', 'name': 'Usuario Demo', 'email': 'demo@gravity.com'},
      }));
    await peticion.response.close();
  });
  return servidor;
}
