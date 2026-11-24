/// Modelo de usuario que devuelve la API.
///
/// Es inmutable: para "modificarlo" se usa [copyWith].
/// No guarda la contraseña: nunca debe viajar de vuelta desde el servidor.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  /// Crea un [User] desde el JSON de la API.
  /// Lanza [FormatException] si faltan campos o tienen otro tipo.
  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final email = json['email'];
    if (id == null || name is! String || email is! String) {
      throw const FormatException('Usuario inválido en la respuesta');
    }
    return User(id: id.toString(), name: name, email: email);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };

  User copyWith({String? id, String? name, String? email}) => User(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
      );

  /// Iniciales para el avatar: "Ana Pérez" -> "AP".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.id == id &&
      other.name == name &&
      other.email == email;

  @override
  int get hashCode => Object.hash(id, name, email);

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}
