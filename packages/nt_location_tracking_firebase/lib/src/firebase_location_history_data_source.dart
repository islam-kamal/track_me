import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';

/// Firebase Realtime Database adapter for [LocationHistoryDataSource].
///
/// Provides live streams for map/history UI without coupling the core plugin
/// to Firebase listeners.
class FirebaseLocationHistoryDataSource implements LocationHistoryDataSource {
  FirebaseLocationHistoryDataSource({
    FirebaseDatabase? database,
    this.databaseUrl,
  }) : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;
  final String? databaseUrl;

  DatabaseReference _userRef(String subjectId) {
    if (databaseUrl != null && databaseUrl!.isNotEmpty) {
      return FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: databaseUrl!,
      ).ref().child('users').child(subjectId);
    }
    return _database.ref().child('users').child(subjectId);
  }

  @override
  Stream<LocationPoint?> watchCurrentLocation(String subjectId) {
    return _userRef(subjectId).child('currentLocation').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map<Object?, Object?>) {
        return LocationPoint.fromMap(value);
      }
      return null;
    });
  }

  @override
  Stream<List<LocationPoint>> watchLocationHistory(String subjectId) {
    return _userRef(subjectId).child('locations').onValue.map((event) {
      return _parseLocationPoints(event.snapshot.value);
    });
  }

  static List<LocationPoint> _parseLocationPoints(Object? value) {
    final points = <LocationPoint>[];
    if (value is! Map<Object?, Object?>) {
      return points;
    }

    for (final entry in value.entries) {
      final data = entry.value;
      if (data is Map<Object?, Object?>) {
        points.add(LocationPoint.fromMap(data));
      }
    }

    points.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return points;
  }
}
