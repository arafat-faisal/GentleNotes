import '../../../../models/models.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere((e) => e.name == map['role'], orElse: () => UserRole.guest),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
