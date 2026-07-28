import 'platform_role.dart';

/// Dev-only mock identity for local role switching without OAuth.
class MockUser {
  const MockUser({
    required this.id,
    required this.name,
    required this.email,
    required this.organization,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String organization;
  final PlatformRole role;

  static MockUser? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final email = json['email'] as String?;
    final organization = json['organization'] as String?;
    final role = PlatformRoleX.tryParse(json['role'] as String?);
    if (id == null ||
        id.trim().isEmpty ||
        name == null ||
        name.trim().isEmpty ||
        email == null ||
        email.trim().isEmpty ||
        role == null) {
      return null;
    }
    return MockUser(
      id: id.trim(),
      name: name.trim(),
      email: email.trim(),
      organization: (organization ?? '').trim(),
      role: role,
    );
  }
}
