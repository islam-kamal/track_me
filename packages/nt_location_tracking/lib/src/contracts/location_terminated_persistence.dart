/// Optional native/headless persistence settings for when the Flutter engine
/// is not running (app terminated or swiped away).
///
/// Implement on your [LocationStorageDataSource] (or via adapter package) so
/// the plugin can still write locations to your backend from:
/// - **Android**: foreground service (no Dart isolate)
/// - **iOS**: BGL headless Dart task
abstract class LocationTerminatedPersistenceProvider {
  /// Serialized adapter configuration understood by the plugin.
  ///
  /// Supported `adapter` values:
  /// - `firebase` — requires `databaseUrl` (optional)
  /// - `http` — requires `endpointTemplate` with `{subjectId}` placeholder,
  ///   `headers` map (include `Authorization`), and optional `collectorId`
  Map<String, dynamic> toTerminatedPersistenceMap();
}
