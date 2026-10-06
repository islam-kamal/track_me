import 'package:nt_location_tracking/nt_location_tracking.dart';

import '../firebase/track_me_backend.dart';

/// Starts continuous tracking for the signed-in user and keeps it running.
class TrackingSession {
  TrackingSession._();

  static bool _ready = false;

  static const Duration saveInterval = Duration(minutes: 5);
  static const double saveDistanceMeters = 10;

  static Future<void> ensureStarted(String uid) async {
    await LocationTracking.initialize(
      config: LocationTrackingConfig(
        userId: uid,
        androidNotificationTitle: 'Track Me',
        androidNotificationText: 'Recording location for this account',
        distanceFilterMeters: saveDistanceMeters,
        intervalSeconds: saveInterval.inSeconds,
        enableReverseGeocoding: false,
      ),
      dependencies: TrackMeBackend.dependencies,
    );
    _ready = true;
    await LocationTracking.start();
  }

  static Future<void> stopIfRunning() async {
    if (!_ready) {
      return;
    }
    if (await LocationTracking.isTracking()) {
      await LocationTracking.stop();
    }
  }
}
