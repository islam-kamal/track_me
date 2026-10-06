import 'dart:math' as math;

import '../models/location_point.dart';

/// Decides when a location should be written to the backend.
///
/// Saves occur when **either**:
/// - [intervalSeconds] have passed since the last successful save, or
/// - the device moved at least [distanceFilterMeters] since the last save.
///
/// Native trackers may emit more often; this layer throttles API/storage calls.
class LocationPersistencePolicy {
  LocationPersistencePolicy({
    required this.intervalSeconds,
    required this.distanceFilterMeters,
  });

  final int intervalSeconds;
  final double distanceFilterMeters;

  LocationPoint? _lastPersistedPoint;
  DateTime? _lastPersistedAt;
  LocationPoint? _latestLocation;

  LocationPoint? get latestLocation => _latestLocation;

  /// Whether [stop] should write [latestLocation] to the backend.
  ///
  /// Returns true when there is a location that was never saved, or that
  /// differs from the last successful save.
  bool needsFlushOnStop() {
    final latest = _latestLocation;
    if (latest == null) {
      return false;
    }
    final last = _lastPersistedPoint;
    if (last == null) {
      return true;
    }
    return latest.latitude != last.latitude ||
        latest.longitude != last.longitude ||
        latest.timestamp != last.timestamp;
  }

  LocationPoint? get lastPersistedPoint => _lastPersistedPoint;

  DateTime? get lastPersistedAt => _lastPersistedAt;

  void onLocationReceived(LocationPoint point) {
    _latestLocation = point;
  }

  /// Whether [point] should be saved now (first fix, time, or distance).
  bool shouldPersist(LocationPoint point, {DateTime? now}) {
    final at = now ?? DateTime.now();
    if (_lastPersistedPoint == null || _lastPersistedAt == null) {
      return true;
    }

    if (at.difference(_lastPersistedAt!).inSeconds >= intervalSeconds) {
      return true;
    }

    return distanceBetweenMeters(_lastPersistedPoint!, point) >=
        distanceFilterMeters;
  }

  /// Latest location due for a time-based save (e.g. device stationary).
  LocationPoint? pendingPeriodicSave({DateTime? now}) {
    final latest = _latestLocation;
    if (latest == null) {
      return null;
    }
    if (_lastPersistedPoint == null || _lastPersistedAt == null) {
      return latest;
    }

    final at = now ?? DateTime.now();
    if (at.difference(_lastPersistedAt!).inSeconds >= intervalSeconds) {
      return latest;
    }
    return null;
  }

  void markPersisted(LocationPoint point, {DateTime? at}) {
    _lastPersistedPoint = point;
    _lastPersistedAt = at ?? DateTime.now();
    _latestLocation = point;
  }

  void reset() {
    _lastPersistedPoint = null;
    _lastPersistedAt = null;
    _latestLocation = null;
  }

  static double distanceBetweenMeters(LocationPoint from, LocationPoint to) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final dLat = _toRadians(to.latitude - from.latitude);
    final dLng = _toRadians(to.longitude - from.longitude);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
