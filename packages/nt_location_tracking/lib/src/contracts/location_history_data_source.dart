import '../models/location_point.dart';

/// Contract for **reading** location history from a backend.
///
/// Optional — only needed when your UI displays stored locations (maps, lists).
/// Tracking itself works with [LocationStorageDataSource] alone.
abstract class LocationHistoryDataSource {
  /// Stream of the latest saved location for [subjectId], or null if none.
  Stream<LocationPoint?> watchCurrentLocation(String subjectId);

  /// Stream of all historical points for [subjectId], newest first.
  Stream<List<LocationPoint>> watchLocationHistory(String subjectId);
}
