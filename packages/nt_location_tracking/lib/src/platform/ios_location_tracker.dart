import 'dart:async';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

import '../config/location_tracking_config.dart';
import '../geocoding/location_geocoder.dart';
import '../models/location_point.dart';
import 'platform_location_tracker.dart';

/// iOS tracker using [flutter_background_geolocation].
///
/// BGL is used instead of native CLLocationManager because it supports
/// `stopOnTerminate: false` — tracking resumes after force-quit via geofencing.
/// Locations are NOT saved here; [LocationTracking] persists via the injected
/// [LocationStorageDataSource] when [onLocation] fires.
class IosLocationTracker implements PlatformLocationTracker {
  final _controller = StreamController<LocationPoint>.broadcast();
  LocationPoint? _latest;
  bool _listenersRegistered = false;
  bool _enableReverseGeocoding = false;

  @override
  Stream<LocationPoint> get onLocation => _controller.stream;

  @override
  Future<void> initialize(LocationTrackingConfig config) async {
    _enableReverseGeocoding = config.enableReverseGeocoding;
    if (!_listenersRegistered) {
      bg.BackgroundGeolocation.onLocation(_onLocation);
      bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
      _listenersRegistered = true;
    }

    await bg.BackgroundGeolocation.ready(
      bg.Config(
        stopOnTerminate: false,
        startOnBoot: true,
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: config.distanceFilterMeters,
        pausesLocationUpdatesAutomatically: false,
        locationAuthorizationRequest: 'Always',
        backgroundPermissionRationale: bg.PermissionRationale(
          title:
              'Allow location access so tracking continues when the app is closed.',
          message:
              'This app collects location data to track your position even when closed.',
          positiveAction: 'Change to "{backgroundPermissionOptionLabel}"',
          negativeAction: 'Cancel',
        ),
      ),
    );
  }

  void _onLocation(bg.Location location) {
    unawaited(_handleLocation(location, isMoving: location.isMoving));
  }

  void _onMotionChange(bg.Location location) {
    unawaited(_handleLocation(location, isMoving: location.isMoving));
  }

  Future<void> _handleLocation(bg.Location location, {bool? isMoving}) async {
    String? address;
    if (_enableReverseGeocoding) {
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
      isMoving: isMoving ?? location.isMoving,
    );
    _latest = point;
    _controller.add(point);
  }

  @override
  Future<void> start() async {
    await bg.BackgroundGeolocation.start();
  }

  @override
  Future<void> stop() async {
    await bg.BackgroundGeolocation.stop();
  }

  @override
  Future<bool> isTracking() async {
    final state = await bg.BackgroundGeolocation.state;
    return state.enabled;
  }

  @override
  Future<LocationPoint?> getCurrentLocation() async {
    if (_latest != null) {
      return _latest;
    }
    try {
      final location = await bg.BackgroundGeolocation.getCurrentPosition(
        samples: 1,
        persist: false,
      );
      final point = LocationPoint(
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
        accuracy: location.coords.accuracy,
        altitude: location.coords.altitude,
        speed: location.coords.speed,
        heading: location.coords.heading,
        timestamp: _parseTimestamp(location.timestamp),
        platform: 'ios',
        isMoving: location.isMoving,
      );
      _latest = point;
      return point;
    } catch (_) {
      return null;
    }
  }

  Future<int> requestPermissions() {
    return bg.BackgroundGeolocation.requestPermission();
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
