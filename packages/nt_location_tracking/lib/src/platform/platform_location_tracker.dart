import '../config/location_tracking_config.dart';
import '../models/location_point.dart';

/// Platform abstraction for starting/stopping tracking and receiving locations.
///
/// Implementations hide iOS BGL vs Android foreground service details from
/// the rest of the package.
abstract class PlatformLocationTracker {
  /// Prepare native SDK with [config] (notification text, intervals, etc.).
  Future<void> initialize(LocationTrackingConfig config);

  Future<void> start();
  Future<void> stop();
  Future<bool> isTracking();
  Stream<LocationPoint> get onLocation;
  Future<LocationPoint?> getCurrentLocation();
}
