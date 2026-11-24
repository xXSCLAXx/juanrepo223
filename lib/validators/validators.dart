/// Mensajes de validación centralizados (las pruebas usan estas constantes).
abstract final class ValidationMessages {
  static const String fieldRequired = 'Este campo es obligatorio';

  static const String nameRequired = 'El nombre es obligatorio';
  static const String nameTooShort = 'El nombre debe tener al menos 2 caracteres';
  static const String nameTooLong = 'El nombre no puede superar 50 caracteres';
  static const String nameInvalid = 'El nombre solo puede contener letras y espacios';

  static const String emailRequired = 'El correo es obligatorio';
  static const String emailTooLong = 'El correo no puede superar 254 caracteres';
  static const String emailInvalid = 'Ingresa un correo válido';

  static const String passwordRequired = 'La contraseña es obligatoria';
  static const String passwordTooShort = 'Debe tener al menos 8 caracteres';
  static const String passwordTooLong = 'No puede superar 64 caracteres';
  static const String passwordSpaces = 'No puede contener espacios';
  static const String passwordUppercase = 'Debe incluir una letra mayúscula';
  static const String passwordLowercase = 'Debe incluir una letra minúscula';
  static const String passwordNumber = 'Debe incluir un número';
  static const String passwordSymbol = 'Debe incluir un símbolo (por ejemplo ! @ # \$)';

  static const String confirmRequired = 'Confirma tu contraseña';
  static const String passwordsDontMatch = 'Las contraseñas no coinciden';
}

/// Validaciones de formularios.
///
/// Convención de Flutter: devuelven `null` si el valor es válido,
/// o un mensaje de error si no lo es. Así se usan directo en
/// `TextFormField(validator: Validators.email)`.
abstract final class Validators {
  static const int nameMinLength = 2;
  static const int nameMaxLength = 50;
  static const int emailMaxLength = 254;
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 64;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,}$',
  );
  static final RegExp _nameRegex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ' ]+$");
  static final RegExp _upper = RegExp('[A-Z]');
  static final RegExp _lower = RegExp('[a-z]');
  static final RegExp _digit = RegExp('[0-9]');
  static final RegExp _symbol = RegExp('[^A-Za-z0-9]');

  /// Quita espacios y pasa a minúsculas: "  Ana@Mail.COM " -> "ana@mail.com".
  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static String? notEmpty(
    String? value, {
    String message = ValidationMessages.fieldRequired,
  }) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationMessages.nameRequired;
    }
    final name = value.trim();
    if (name.length < nameMinLength) return ValidationMessages.nameTooShort;
    if (name.length > nameMaxLength) return ValidationMessages.nameTooLong;
    if (!_nameRegex.hasMatch(name)) return ValidationMessages.nameInvalid;
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationMessages.emailRequired;
    }
    final email = value.trim();
    if (email.length > emailMaxLength) return ValidationMessages.emailTooLong;
    if (email.contains('..') || !_emailRegex.hasMatch(email)) {
      return ValidationMessages.emailInvalid;
    }
    return null;
  }

  /// Regla de negocio para contraseñas nuevas (registro).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationMessages.passwordRequired;
    }
    if (value.length < passwordMinLength) {
      return ValidationMessages.passwordTooShort;
    }
    if (value.length > passwordMaxLength) {
      return ValidationMessages.passwordTooLong;
    }
    if (value.contains(' ')) return ValidationMessages.passwordSpaces;
    if (!_upper.hasMatch(value)) return ValidationMessages.passwordUppercase;
    if (!_lower.hasMatch(value)) return ValidationMessages.passwordLowercase;
    if (!_digit.hasMatch(value)) return ValidationMessages.passwordNumber;
    if (!_symbol.hasMatch(value)) return ValidationMessages.passwordSymbol;
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return ValidationMessages.confirmRequired;
    }
    if (value != original) return ValidationMessages.passwordsDontMatch;
    return null;
  }
}
