// PRUEBAS UNITARIAS: modelos de datos (conversión JSON, igualdad, seguridad).
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/models/auth_session.dart';
import 'package:flutter23/models/user.dart';

import '../mocks/test_data.dart';

void main() {
  group('User', () {
    test('fromJson crea el usuario', () {
      final user = User.fromJson(kUserJson);
      expect(user, kUser);
    });

    test('fromJson convierte un id numérico a texto', () {
      final user = User.fromJson({'id': 7, 'name': 'Ana', 'email': 'a@b.co'});
      expect(user.id, '7');
    });

    test('fromJson lanza FormatException si falta un campo', () {
      expect(
        () => User.fromJson({'id': '1', 'name': 'Ana'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('toJson -> fromJson devuelve el mismo usuario (ida y vuelta)', () {
      expect(User.fromJson(kUser.toJson()), kUser);
    });

    test('toJson no incluye contraseña', () {
      expect(kUser.toJson().keys, isNot(contains('password')));
    });

    test('igualdad y hashCode por valor', () {
      const a = User(id: '1', name: 'Ana', email: 'a@b.co');
      const b = User(id: '1', name: 'Ana', email: 'a@b.co');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a.copyWith(name: 'Otra'), isFalse);
    });

    test('initials', () {
      expect(const User(id: '1', name: 'Ana Pérez', email: '').initials, 'AP');
      expect(const User(id: '1', name: 'ana', email: '').initials, 'A');
      expect(
        const User(id: '1', name: 'Ana María López', email: '').initials,
        'AM',
      );
    });
  });

  group('AuthSession', () {
    test('fromJson crea la sesión', () {
      final session = AuthSession.fromJson(kSessionJson);
      expect(session.token, 'token-de-prueba-123');
      expect(session.user, kUser);
    });

    test('fromJson lanza FormatException si el token está vacío', () {
      expect(
        () => AuthSession.fromJson({'token': '', 'user': kUserJson}),
        throwsA(isA<FormatException>()),
      );
    });

    test('toString NO muestra el token', () {
      expect(kSession.toString(), isNot(contains(kSession.token)));
      expect(kSession.toString(), contains('***'));
    });
  });
}
