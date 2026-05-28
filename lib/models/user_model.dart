enum UserRole { driver, security, admin }

class User {
  final int id;
  final String email;
  final String name;
  final UserRole role;
  final String? token;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      role: _parseRole(json['role'] as String? ?? json['role_name'] as String? ?? 'driver'),
      token: json['token'] as String?,
    );
  }

  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return UserRole.driver;
      case 'security':
        return UserRole.security;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.driver;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role.name,
        'token': token,
      };

  bool get canCreateQueue => role == UserRole.driver || role == UserRole.admin;
  bool get canApproveQueue => role == UserRole.security || role == UserRole.admin;
  bool get canScanBarcode => true; // All roles can scan
  bool get canViewAllQueues => role == UserRole.admin;
}

class AuthResponse {
  final User user;
  final String token;

  AuthResponse({required this.user, required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}
