import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_service.dart';
import '../auth/profile_repository.dart';
import '../auth/user_profile.dart';
import '../tracking/tracking_session.dart';
import 'admin_home_screen.dart';
import 'permission_screen.dart';
import 'sign_in_screen.dart';
import 'user_home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _auth = AuthService();
  late final Stream<User?> _authState = _auth.authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const SignInScreen();
        }
        return _ProfileGate(user: user);
      },
    );
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({required this.user});

  final User user;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late Future<UserProfile> _profile;

  @override
  void initState() {
    super.initState();
    _profile = ProfileRepository().ensureProfile(widget.user);
  }

  @override
  void didUpdateWidget(covariant _ProfileGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _profile = ProfileRepository().ensureProfile(widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load this account.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => AuthService().signOut(),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final profile = snapshot.data!;
        if (profile.isAdmin) {
          return _AdminEntry(profile: profile);
        }
        return _TrackedUserEntry(profile: profile);
      },
    );
  }
}

class _AdminEntry extends StatefulWidget {
  const _AdminEntry({required this.profile});

  final UserProfile profile;

  @override
  State<_AdminEntry> createState() => _AdminEntryState();
}

class _AdminEntryState extends State<_AdminEntry> {
  @override
  void initState() {
    super.initState();
    unawaited(TrackingSession.ensureNotTracking(widget.profile.uid));
  }

  @override
  Widget build(BuildContext context) {
    return AdminHomeScreen(profile: widget.profile);
  }
}

class _TrackedUserEntry extends StatefulWidget {
  const _TrackedUserEntry({required this.profile});

  final UserProfile profile;

  @override
  State<_TrackedUserEntry> createState() => _TrackedUserEntryState();
}

class _TrackedUserEntryState extends State<_TrackedUserEntry> {
  bool? _acknowledged;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _acknowledged = prefs.getBool(permissionAcknowledgedKey) ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final acknowledged = _acknowledged;
    if (acknowledged == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!acknowledged) {
      return PermissionScreen(
        userId: widget.profile.uid,
        onGranted: () => setState(() => _acknowledged = true),
      );
    }
    return UserHomeScreen(profile: widget.profile);
  }
}
