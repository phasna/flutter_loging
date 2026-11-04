/// Utilisateur connecté, construit à partir de la réponse JSON de l'API.
class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final int role;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });

  String get fullName => '$firstName $lastName';

  /// Libellé lisible du rôle numérique renvoyé par l'API.
  String get roleLabel => switch (role) {
        1 => 'Administrateur',
        2 => 'Utilisateur',
        _ => 'Rôle $role',
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: (json['role'] as num?)?.toInt() ?? 0,
    );
  }
}
