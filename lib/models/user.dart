// lib/models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final String? phone;
  final String? department;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.phone,
    this.department,
  }); // ... rest of User class methods (fromJson, toJson, copyWith)
}
