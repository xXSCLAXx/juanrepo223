// PRUEBAS UNITARIAS: validaciones de formularios.
// Incluye casos POSITIVOS (válidos), NEGATIVOS (inválidos) y de VALORES LÍMITE.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter23/validators/validators.dart';

void main() {
  group('Validators.email', () {
    group('positivos', () {
      const validos = [
        'ana@gravity.com',
        'ANA.PEREZ@Gravity.COM',
        'user+tag@mail.co',
        'nombre_apellido@sub.dominio.org',
        '  con.espacios@gravity.com  ', // se ignoran espacios al inicio/fin
      ];
      for (final email in validos) {
        test('acepta "$email"', () {
          expect(Validators.email(email), isNull);
        });
      }
    });

    group('negativos', () {
      test('null, vacío o solo espacios -> obligatorio', () {
        expect(Validators.email(null), ValidationMessages.emailRequired);
        expect(Validators.email(''), ValidationMessages.emailRequired);
        expect(Validators.email('   '), ValidationMessages.emailRequired);
      });

      const invalidos = [
        'ana',
        'ana@',
        '@gravity.com',
        'ana@gravity',
        'ana@@gravity.com',
        'ana@gravity..com',
        'ana..perez@gravity.com',
        'ana perez@gravity.com',
        'ana@gravity.c',
        'ana@gravity.123',
      ];
      for (final email in invalidos) {
        test('rechaza "$email"', () {
          expect(Validators.email(email), ValidationMessages.emailInvalid);
        });
      }
    });

    group('valores límite', () {
      const dominio = '@gravity.com';

      test('254 caracteres (máximo) es válido', () {
        final email = 'a' * (254 - dominio.length) + dominio;
        expect(email.length, 254);
        expect(Validators.email(email), isNull);
      });

      test('255 caracteres es inválido', () {
        final email = 'a' * (255 - dominio.length) + dominio;
        expect(email.length, 255);
        expect(Validators.email(email), ValidationMessages.emailTooLong);
      });

      test('dominio de 2 letras (mínimo) es válido', () {
        expect(Validators.email('ana@gravity.bo'), isNull);
      });
    });
  });

  group('Validators.password', () {
    group('positivos', () {
      test('contraseña fuerte', () {
        expect(Validators.password('Gravity123!'), isNull);
      });
    });

    group('negativos', () {
      test('null o vacía -> obligatoria', () {
        expect(Validators.password(null), ValidationMessages.passwordRequired);
        expect(Validators.password(''), ValidationMessages.passwordRequired);
      });

      final casos = <String, String>{
        'Ab1!': ValidationMessages.passwordTooShort,
        'gravity123!': ValidationMessages.passwordUppercase,
        'GRAVITY123!': ValidationMessages.passwordLowercase,
        'Gravity!!!!': ValidationMessages.passwordNumber,
        'Gravity1234': ValidationMessages.passwordSymbol,
        'Gravity 123!': ValidationMessages.passwordSpaces,
      };
      for (final caso in casos.entries) {
        test('"${caso.key}" -> "${caso.value}"', () {
          expect(Validators.password(caso.key), caso.value);
        });
      }
    });

    group('valores límite', () {
      test('7 caracteres (mínimo - 1) es inválido', () {
        expect(Validators.password('Abcde1!'), ValidationMessages.passwordTooShort);
      });

      test('8 caracteres (mínimo) es válido', () {
        expect(Validators.password('Abcdef1!'), isNull);
      });

      test('64 caracteres (máximo) es válido', () {
        final pass = 'Aa1!${'a' * 60}';
        expect(pass.length, 64);
        expect(Validators.password(pass), isNull);
      });

      test('65 caracteres (máximo + 1) es inválido', () {
        final pass = 'Aa1!${'a' * 61}';
        expect(pass.length, 65);
        expect(Validators.password(pass), ValidationMessages.passwordTooLong);
      });
    });
  });

  group('Validators.name', () {
    test('positivos: nombres con tildes, ñ y apóstrofe', () {
      expect(Validators.name('Ana'), isNull);
      expect(Validators.name('José Núñez'), isNull);
      expect(Validators.name("Sinéad O'Connor"), isNull);
    });

    test('negativos: vacío, números o símbolos', () {
      expect(Validators.name(''), ValidationMessages.nameRequired);
      expect(Validators.name('   '), ValidationMessages.nameRequired);
      expect(Validators.name('Ana123'), ValidationMessages.nameInvalid);
      expect(Validators.name('Ana_Pérez'), ValidationMessages.nameInvalid);
    });

    test('límite: 1 carácter inválido, 2 válido', () {
      expect(Validators.name('A'), ValidationMessages.nameTooShort);
      expect(Validators.name('Al'), isNull);
    });

    test('límite: 50 caracteres válido, 51 inválido', () {
      expect(Validators.name('a' * 50), isNull);
      expect(Validators.name('a' * 51), ValidationMessages.nameTooLong);
    });
  });

  group('Validators.confirmPassword', () {
    test('coinciden -> válido', () {
      expect(Validators.confirmPassword('Gravity123!', 'Gravity123!'), isNull);
    });

    test('no coinciden -> error', () {
      expect(
        Validators.confirmPassword('Gravity123?', 'Gravity123!'),
        ValidationMessages.passwordsDontMatch,
      );
    });

    test('vacía -> pide confirmar', () {
      expect(
        Validators.confirmPassword('', 'Gravity123!'),
        ValidationMessages.confirmRequired,
      );
    });
  });

  group('Validators.notEmpty y normalizeEmail', () {
    test('notEmpty usa el mensaje indicado', () {
      expect(Validators.notEmpty(''), ValidationMessages.fieldRequired);
      expect(Validators.notEmpty(' ', message: 'X'), 'X');
      expect(Validators.notEmpty('hola'), isNull);
    });

    test('normalizeEmail quita espacios y pasa a minúsculas', () {
      expect(Validators.normalizeEmail('  Ana@Gravity.COM '), 'ana@gravity.com');
    });
  });
}
