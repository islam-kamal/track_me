/// Builds native/headless HTTP persistence config with required auth.
///
/// Use in your [LocationStorageDataSource] implementation:
/// ```dart
/// class MyHttpStorage implements LocationStorageDataSource, LocationTerminatedPersistenceProvider {
///   @override
///   Map<String, dynamic> toTerminatedPersistenceMap() {
///     return HttpTerminatedPersistenceConfig(
///       endpointTemplate: 'https://api.example.com/users/{subjectId}/locations',
///       authToken: LocationTrackingSession.authToken!,
///       collectorId: LocationTrackingSession.collectorId,
///     ).toMap();
///   }
/// }
/// ```
class HttpTerminatedPersistenceConfig {
  const HttpTerminatedPersistenceConfig({
    required this.endpointTemplate,
    required this.authToken,
    this.collectorId,
    this.extraHeaders = const {},
  });

  final String endpointTemplate;
  final String authToken;
  final String? collectorId;
  final Map<String, String> extraHeaders;

  Map<String, dynamic> toMap() {
    if (authToken.trim().isEmpty) {
      throw StateError(
        'Auth token is required for terminated location persistence.',
      );
    }

    return {
      'adapter': 'http',
      'endpointTemplate': endpointTemplate,
      if (collectorId != null && collectorId!.trim().isNotEmpty)
        'collectorId': collectorId,
      'headers': {
        'Authorization': 'Bearer $authToken',
        ...extraHeaders,
      },
    };
  }
}
