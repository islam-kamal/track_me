import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';

/// Firebase Realtime Database adapter for [LocationStorageDataSource].
///
/// Also supports terminated-app persistence on Android (native) and iOS
/// (BGL headless) via [LocationTerminatedPersistenceProvider].
class FirebaseLocationStorageDataSource
    implements
        LocationStorageDataSource,
        LocationTerminatedPersistenceProvider {
  FirebaseLocationStorageDataSource({
    FirebaseDatabase? database,
    this.databaseUrl,
  }) : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  /// Optional override when using a non-default RTDB instance.
  final String? databaseUrl;

  DatabaseReference get _root {
    if (databaseUrl != null && databaseUrl!.isNotEmpty) {
      return FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: databaseUrl!,
      ).ref();
    }
    return _database.ref();
  }

  @override
  Map<String, dynamic> toTerminatedPersistenceMap() {
    return {
      'adapter': 'firebase',
      'databaseUrl': databaseUrl ?? '',
    };
  }

  @override
  Future<void> saveLocation(
    LocationPoint point, {
    required String subjectId,
  }) async {
    try {
      final data = point.toMap();
      final userRef = _root.child('users').child(subjectId);

      // Dual-write: latest snapshot + append-only history.
      await userRef.child('currentLocation').set(data);
      await userRef.child('locations').push().set(data);
    } on FirebaseException catch (error) {
      throw _mapFirebaseError(error);
    } catch (error) {
      throw NetworkException('Failed to save location to Firebase.', cause: error);
    }
  }

  /// Maps Firebase-specific errors to backend-agnostic exceptions.
  TrackingException _mapFirebaseError(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return AuthenticationException(
        'Firebase permission denied.',
        cause: error,
      );
    }
    return NetworkException(
      error.message ?? 'Firebase error.',
      cause: error,
    );
  }
}
