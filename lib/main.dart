import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';

import 'app.dart';
import 'firebase/default_firebase_options.dart';
import 'firebase/track_me_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocationTracking.configureHeadlessBootstrap(_bootstrapTracking);
  await LocationTracking.registerHeadlessTask();

  var firebaseReady = false;
  if (DefaultFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await TrackMeBackend.initialize();
      firebaseReady = true;
    } catch (error, stackTrace) {
      debugPrint('Firebase init failed: $error\n$stackTrace');
    }
  }

  runApp(TrackMeApp(firebaseReady: firebaseReady));
}

Future<LocationTrackingDependencies> _bootstrapTracking() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await TrackMeBackend.initialize();
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    try {
      await auth.authStateChanges().first.timeout(const Duration(seconds: 5));
    } catch (_) {
      // Headless saves still attempt the write; rules reject it if auth is gone.
    }
  }
  return TrackMeBackend.dependencies;
}
