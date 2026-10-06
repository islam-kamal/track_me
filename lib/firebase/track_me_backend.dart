import 'package:firebase_core/firebase_core.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';
import 'package:nt_location_tracking_firebase/nt_location_tracking_firebase.dart';

import 'database_targets.dart';

/// Wires the location plugin to the new Realtime Database.
class TrackMeBackend {
  TrackMeBackend._();

  static FirebaseLocationStorageDataSource? _storage;
  static FirebaseLocationHistoryDataSource? _history;

  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      throw StateError(
        'Firebase.initializeApp must run before TrackMeBackend.initialize().',
      );
    }
    _storage ??= FirebaseLocationStorageDataSource(
      databaseUrl: trackingDatabaseUrl,
    );
    _history ??= FirebaseLocationHistoryDataSource(
      databaseUrl: trackingDatabaseUrl,
    );
  }

  static LocationTrackingDependencies get dependencies {
    final storage = _storage;
    final history = _history;
    if (storage == null || history == null) {
      throw StateError('TrackMeBackend.initialize() has not run.');
    }
    return LocationTrackingDependencies(
      storage: storage,
      history: history,
    );
  }

  static FirebaseLocationHistoryDataSource get history {
    final value = _history;
    if (value == null) {
      throw StateError('TrackMeBackend.initialize() has not run.');
    }
    return value;
  }
}
