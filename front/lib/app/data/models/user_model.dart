class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final bool confirmed;
  final bool blocked;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.confirmed,
    required this.blocked,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final parsedRole = _extractRoleName(json['role']);

    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: parsedRole,
      confirmed: json['confirmed'] == true,
      blocked: json['blocked'] == true,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  static String _extractRoleName(dynamic rawRole) {
    if (rawRole == null) return 'Inconnu';

    if (rawRole is String) {
      final value = rawRole.trim();
      return value.isEmpty ? 'Inconnu' : value;
    }

    if (rawRole is Map) {
      final roleMap = Map<String, dynamic>.from(rawRole);

      final directName = roleMap['name'] ?? roleMap['type'];
      if (directName != null && directName.toString().trim().isNotEmpty) {
        return directName.toString().trim();
      }

      final data = roleMap['data'];
      if (data is Map) {
        final dataMap = Map<String, dynamic>.from(data);
        final dataName = dataMap['name'] ?? dataMap['type'];
        if (dataName != null && dataName.toString().trim().isNotEmpty) {
          return dataName.toString().trim();
        }

        final attributes = dataMap['attributes'];
        if (attributes is Map) {
          final attrMap = Map<String, dynamic>.from(attributes);
          final attrName = attrMap['name'] ?? attrMap['type'];
          if (attrName != null && attrName.toString().trim().isNotEmpty) {
            return attrName.toString().trim();
          }
        }
      }
    }

    return 'Inconnu';
  }

  Map<String, dynamic> toCreateJson({String? password}) {
    return {
      'username': username,
      'email': email,
      if (password != null && password.trim().isNotEmpty)
        'password': password.trim(),
      'confirmed': confirmed,
      'blocked': blocked,
      'role': role,
    };
  }

  Map<String, dynamic> toUpdateJson({String? password}) {
    return {
      'username': username,
      'email': email,
      if (password != null && password.trim().isNotEmpty)
        'password': password.trim(),
      'confirmed': confirmed,
      'blocked': blocked,
      'role': role,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? role,
    bool? confirmed,
    bool? blocked,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      confirmed: confirmed ?? this.confirmed,
      blocked: blocked ?? this.blocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
