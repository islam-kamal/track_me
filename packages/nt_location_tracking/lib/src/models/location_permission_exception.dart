/// Thrown when the user denies location permission during [LocationTracking.start].
///
/// Separate from [TrackingException] because permission is a device/OS concern,
/// not a backend failure.
class LocationPermissionException implements Exception {
  const LocationPermissionException(this.message);

  final String message;

  @override
  String toString() => 'LocationPermissionException: $message';
}
