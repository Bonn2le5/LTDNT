enum UserRole { user, gate, admin }

/// Matches backend User. Phone is presentation data; passwords are excluded.
class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.role = UserRole.user,
  });
  final int id;
  final String fullName;
  final String email;
  final UserRole role;
}
