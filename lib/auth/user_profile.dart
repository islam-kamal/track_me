import 'account_role.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String uid;
  final String email;
  final String displayName;
  final AccountRole role;

  bool get isAdmin => role == AccountRole.admin;

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return email.isEmpty ? '?' : email[0].toUpperCase();
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Map<String, Object> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
    };
  }

  factory UserProfile.fromValue(String uid, Object value) {
    final data = Map<Object?, Object?>.from(value as Map);
    final email = data['email'] as String? ?? '';
    final displayName = data['displayName'] as String? ?? '';
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName.isEmpty ? email : displayName,
      role: AccountRole.parse(data['role']),
    );
  }
}
