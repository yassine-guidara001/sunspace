class User {
  final int id;
  final String name;
  final String email;
  final String role; // "Admin" ou "Authenticated"
  final String status; // "Confirmé" ou autre
  final DateTime registeredAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.registeredAt,
  });
}
