import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../firebase/database_targets.dart';
import 'account_role.dart';
import 'admin_email_key.dart';
import 'user_profile.dart';

class ProfileRepository {
  ProfileRepository({DatabaseReference? root})
    : _root =
          root ??
          FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: trackingDatabaseUrl,
          ).ref();

  final DatabaseReference _root;

  Future<UserProfile> ensureProfile(User user) async {
    final email = user.email?.trim().toLowerCase() ?? '';
    if (email.isEmpty) {
      throw StateError('This account has no email address.');
    }

    final allowlisted = await _isAdminEmail(email);
    final ref = _root.child('profiles').child(user.uid);
    final snapshot = await ref.get();
    final displayName = _displayName(user, email);

    if (!snapshot.exists || snapshot.value == null) {
      final profile = UserProfile(
        uid: user.uid,
        email: email,
        displayName: displayName,
        role: allowlisted ? AccountRole.admin : AccountRole.user,
      );
      await ref.set(profile.toMap());
      return profile;
    }

    final profile = UserProfile.fromValue(user.uid, snapshot.value as Object);
    if (allowlisted && !profile.isAdmin) {
      await ref.update({'role': AccountRole.admin.name});
      return UserProfile(
        uid: profile.uid,
        email: profile.email,
        displayName: profile.displayName,
        role: AccountRole.admin,
      );
    }
    return profile;
  }

  Future<bool> _isAdminEmail(String email) async {
    final snapshot = await _root.child('admins').child(adminEmailKey(email)).get();
    return snapshot.value == true;
  }

  String _displayName(User user, String email) {
    final name = user.displayName?.trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }
    final local = email.split('@').first;
    return local.isEmpty ? email : local;
  }
}
