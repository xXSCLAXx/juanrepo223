// REPORTE DE COBERTURA (sin instalar nada extra)
//
// `flutter test --coverage` genera coverage/lcov.info, pero en Windows no viene
// la herramienta genhtml para verlo. Este script lo lee y muestra el % por archivo.
//
// Uso:
//   flutter test --coverage
//   dart run tool/coverage_report.dart
//   dart run tool/coverage_report.dart --min 80     (falla si el total < 80 %)
import 'dart:io';

void main(List<String> args) {
  final minIndex = args.indexOf('--min');
  final minimo =
      minIndex >= 0 && minIndex + 1 < args.length ? double.parse(args[minIndex + 1]) : 70.0;

  final archivo = File('coverage/lcov.info');
  if (!archivo.existsSync()) {
    stderr.writeln('No existe coverage/lcov.info.');
    stderr.writeln('Ejecuta primero: flutter test --coverage');
    exitCode = 2;
    return;
  }

  final resultados = <String, List<int>>{}; // archivo -> [cubiertas, total]
  String? actual;
  for (final linea in archivo.readAsLinesSync()) {
    if (linea.startsWith('SF:')) {
      actual = linea.substring(3).replaceAll(r'\', '/');
      resultados[actual] = [0, 0];
    } else if (linea.startsWith('DA:') && actual != null) {
      final partes = linea.substring(3).split(',');
      final conteo = resultados[actual]!;
      conteo[1]++;
      if (int.parse(partes[1]) > 0) conteo[0]++;
    } else if (linea == 'end_of_record') {
      actual = null;
    }
  }

  var cubiertas = 0;
  var total = 0;
  stdout.writeln('COBERTURA POR ARCHIVO');
  stdout.writeln('-' * 70);
  final nombres = resultados.keys.toList()..sort();
  for (final nombre in nombres) {
    final c = resultados[nombre]!;
    cubiertas += c[0];
    total += c[1];
    final pct = c[1] == 0 ? 100.0 : c[0] * 100 / c[1];
    final corto = nombre.contains('lib/')
        ? nombre.substring(nombre.indexOf('lib/'))
        : nombre;
    stdout.writeln(
      '${corto.padRight(50)} ${pct.toStringAsFixed(1).padLeft(6)} %  (${c[0]}/${c[1]})',
    );
  }
  final pctTotal = total == 0 ? 0.0 : cubiertas * 100 / total;
  stdout.writeln('-' * 70);
  stdout.writeln(
    '${'TOTAL'.padRight(50)} ${pctTotal.toStringAsFixed(1).padLeft(6)} %  ($cubiertas/$total)',
  );
  stdout.writeln('Mínimo exigido: ${minimo.toStringAsFixed(0)} %');

  if (pctTotal < minimo) {
    stdout.writeln('RESULTADO: RECHAZADO (cobertura insuficiente)');
    exitCode = 1;
  } else {
    stdout.writeln('RESULTADO: APROBADO');
  }
}
