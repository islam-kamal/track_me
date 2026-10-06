import 'package:flutter/material.dart';

import 'firebase/default_firebase_options.dart';
import 'screens/auth_gate.dart';
import 'screens/setup_screen.dart';
import 'theme/track_me_theme.dart';

class TrackMeApp extends StatelessWidget {
  const TrackMeApp({super.key, this.firebaseReady = false});

  /// True only after [Firebase.initializeApp] succeeded in `main`.
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    final signedInShell =
        firebaseReady && DefaultFirebaseOptions.isConfigured;
    return MaterialApp(
      title: 'Track Me',
      debugShowCheckedModeBanner: false,
      theme: buildTrackMeTheme(),
      builder: (context, child) {
        return SafeArea(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: signedInShell ? const AuthGate() : const SetupScreen(),
    );
  }
}
