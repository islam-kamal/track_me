/// Configuration for native location tracking behavior.
///
/// Contains only platform/tracking settings — no backend URLs or API keys.
/// Backend access is configured separately via [LocationTrackingDependencies].
class LocationTrackingConfig {
  const LocationTrackingConfig({
    required this.userId,
    required this.androidNotificationTitle,
    required this.androidNotificationText,
    this.distanceFilterMeters = 10.0,
    this.intervalSeconds = 30,
    this.enableReverseGeocoding = false,
  });

  /// Opaque identifier forwarded to [LocationStorageDataSource.saveLocation].
  ///
  /// Name kept as `userId` for backward compatibility; can represent any subject.
  final String userId;

  /// Minimum movement (meters) before a backend save is triggered.
  ///
  /// Also forwarded to native Android/iOS trackers to reduce GPS noise.
  final double distanceFilterMeters;

  /// Minimum seconds between backend saves when the device is stationary.
  ///
  /// Also used as the Android foreground service polling interval.
  final int intervalSeconds;

  /// Shown in the Android persistent notification while tracking runs.
  final String androidNotificationTitle;
  final String androidNotificationText;

  /// When `true`, coordinates are reverse-geocoded and [LocationPoint.address]
  /// is included in API saves. When `false`, saves contain lat/lng only.
  final bool enableReverseGeocoding;

  /// Serialized map sent to native Android/iOS plugin via MethodChannel.
  Map<String, dynamic> toPlatformMap() {
    return {
      'userId': userId,
      'distanceFilterMeters': distanceFilterMeters,
      'intervalSeconds': intervalSeconds,
      'androidNotificationTitle': androidNotificationTitle,
      'androidNotificationText': androidNotificationText,
      'enableReverseGeocoding': enableReverseGeocoding,
    };
  }
}
