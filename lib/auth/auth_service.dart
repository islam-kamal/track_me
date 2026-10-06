import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../tracking/tracking_session.dart';
import 'profile_repository.dart';
import 'user_profile.dart';

/// Web OAuth client from google-services.json (client_type 3).
/// Required so Android Google Sign-In returns an ID token for Firebase Auth.
const googleServerClientId =
    '125470470279-th7l3mrpm6nviher3mhegv1i6pvvgis3.apps.googleusercontent.com';

class AuthCancelled implements Exception {
  const AuthCancelled();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    ProfileRepository? profiles,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _profiles = profiles ?? ProfileRepository(),
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             scopes: const ['email'],
             serverClientId: googleServerClientId,
           );

  final FirebaseAuth _auth;
  final ProfileRepository _profiles;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _profiles.ensureProfile(credential.user!);
    });
  }

  Future<UserProfile> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        await user.updateDisplayName(trimmedName);
        await user.reload();
      }
      final refreshed = _auth.currentUser ?? user;
      return _profiles.ensureProfile(refreshed);
    });
  }

  Future<UserProfile> signInWithGoogle() {
    return _guard(() async {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const AuthCancelled();
      }
      final googleAuth = await account.authentication;
      if (googleAuth.idToken == null) {
        throw const AuthFailure(
          'Google did not return an ID token. Check the Firebase SHA-1 for this app.',
        );
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      return _profiles.ensureProfile(result.user!);
    });
  }

  Future<void> signOut() async {
    await TrackingSession.stopIfRunning();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<UserProfile> _guard(Future<UserProfile> Function() action) async {
    try {
      return await action();
    } on AuthCancelled {
      rethrow;
    } on AuthFailure {
      rethrow;
    } on PlatformException catch (error) {
      throw AuthFailure(_googlePlatformMessage(error));
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    } on StateError catch (error) {
      throw AuthFailure(error.message);
    }
  }

  String _googlePlatformMessage(PlatformException error) {
    final details = '${error.code} ${error.message ?? ''} ${error.details ?? ''}';
    if (details.contains('10') || details.contains('DEVELOPER_ERROR')) {
      return 'Google sign-in was rejected for this app build. The debug SHA-1 must be registered in Firebase.';
    }
    if (error.code == 'network_error') {
      return 'Network error. Check your connection.';
    }
    return error.message ?? 'Google sign-in failed.';
  }

  String _messageFor(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'wrong-password' ||
      'user-not-found' ||
      'invalid-credential' => 'Email or password is incorrect.',
      'email-already-in-use' => 'An account with this email already exists.',
      'weak-password' => 'Use a password with at least 6 characters.',
      'network-request-failed' => 'Network error. Check your connection.',
      'too-many-requests' => 'Too many attempts. Try again later.',
      _ => error.message ?? 'Sign-in failed.',
    };
  }
}
