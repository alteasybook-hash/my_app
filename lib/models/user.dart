enum UserRole { admin, user, validator }

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? token; // Le jeton JWT fourni par NestJS après connexion

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: UserRole.values.firstWhere((e) => e.toString().split('.').last == json['role']),
      token: json['token'],
    );
  }
}
