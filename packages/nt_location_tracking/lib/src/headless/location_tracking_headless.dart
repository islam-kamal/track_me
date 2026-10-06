import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

import '../contracts/location_tracking_dependencies.dart';
import '../geocoding/location_geocoder.dart';
import '../models/location_point.dart';
import '../services/location_persistence_policy.dart';
import '../services/location_persistence_service.dart';
import 'terminated_persistence_store.dart';

/// Host app provides this so headless isolates can rebuild [LocationTrackingDependencies].
typedef LocationHeadlessBootstrap =
    Future<LocationTrackingDependencies> Function();

/// Set in `main()` before [LocationTracking.registerHeadlessTask].
LocationHeadlessBootstrap? locationTrackingHeadlessBootstrap;

/// BGL headless entry — runs when the app is terminated (iOS; Android if BGL fires).
@pragma('vm:entry-point')
Future<void> ntLocationTrackingHeadlessTask(bg.HeadlessEvent event) async {
  if (event.name != bg.Event.LOCATION) {
    return;
  }

  final bootstrap = locationTrackingHeadlessBootstrap;
  if (bootstrap == null) {
    return;
  }

  final store = TerminatedPersistenceStore();
  final config = await store.loadConfig();
  if (config == null || !config.isTracking) {
    return;
  }

  final location = event.event as bg.Location;
  String? address;
  if (config.enableReverseGeocoding) {
    address = await LocationGeocoder.reverseGeocode(
      latitude: location.coords.latitude,
      longitude: location.coords.longitude,
    );
  }

  final point = LocationPoint(
    latitude: location.coords.latitude,
    longitude: location.coords.longitude,
    accuracy: location.coords.accuracy,
    altitude: location.coords.altitude,
    speed: location.coords.speed,
    heading: location.coords.heading,
    timestamp: _parseTimestamp(location.timestamp),
    platform: 'ios',
    address: address,
    isMoving: location.isMoving,
  );

  final policy = LocationPersistencePolicy(
    intervalSeconds: config.intervalSeconds,
    distanceFilterMeters: config.distanceFilterMeters,
  );
  await store.applyPolicyState(policy);

  policy.onLocationReceived(point);
  if (!policy.shouldPersist(point)) {
    await store.savePolicyState(policy);
    return;
  }

  try {
    final dependencies = await bootstrap();
    final persistence = LocationPersistenceService(
      storage: dependencies.storage,
      subjectId: config.userId,
    );
    await persistence.persist(
      config.enableReverseGeocoding ? point : point.withoutAddress(),
    );
    policy.markPersisted(point);
    await store.savePolicyState(policy);
  } catch (_) {
    // Headless isolate has no UI — host can reconcile on next foreground launch.
  }
}

DateTime _parseTimestamp(dynamic timestamp) {
  if (timestamp is String) {
    return DateTime.tryParse(timestamp) ?? DateTime.now();
  }
  if (timestamp is num) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
  }
  return DateTime.now();
}

/// Snapshot of tracking config stored for headless/native persistence.
class TerminatedTrackingConfig {
  const TerminatedTrackingConfig({
    required this.userId,
    required this.intervalSeconds,
    required this.distanceFilterMeters,
    required this.isTracking,
    this.enableReverseGeocoding = false,
  });

  final String userId;
  final int intervalSeconds;
  final double distanceFilterMeters;
  final bool isTracking;
  final bool enableReverseGeocoding;
}
