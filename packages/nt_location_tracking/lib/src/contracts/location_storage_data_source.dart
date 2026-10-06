import '../models/location_point.dart';

/// Contract for **writing** tracked locations to a backend.
///
/// Implement this in your app or in an adapter package (Firebase, REST, etc.).
/// The core plugin depends only on this interface — never on a specific SDK.
///
/// Example implementations:
/// - [FirebaseLocationStorageDataSource] (adapter package)
/// - Custom REST/GraphQL/Supabase data source in your app
abstract class LocationStorageDataSource {
  /// Persists [point] for the given [subjectId].
  ///
  /// [subjectId] maps to [LocationTrackingConfig.userId] — use it as a user id,
  /// device id, or any key your backend expects.
  Future<void> saveLocation(
    LocationPoint point, {
    required String subjectId,
  });
}
