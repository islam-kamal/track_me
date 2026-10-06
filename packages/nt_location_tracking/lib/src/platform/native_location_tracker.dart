import 'dart:async';

import 'package:flutter/services.dart';

import '../config/location_tracking_config.dart';
import '../models/location_point.dart';
import 'platform_location_tracker.dart';

/// Android tracker bridged to native [LocationTrackingService] via channels.
///
/// Native service keeps running when app is swiped; Dart receives updates
/// through EventChannel while the Flutter engine is alive.
class NativeLocationTracker implements PlatformLocationTracker {
  static const _methodChannel = MethodChannel('nt_location_tracking');
  static const _eventChannel = EventChannel('nt_location_tracking/events');

  final _controller = StreamController<LocationPoint>.broadcast();
  StreamSubscription<dynamic>? _eventSubscription;
  LocationPoint? _latest;

  @override
  Stream<LocationPoint> get onLocation => _controller.stream;

  @override
  Future<void> initialize(LocationTrackingConfig config) async {
    await _methodChannel.invokeMethod<void>(
      'initialize',
      config.toPlatformMap(),
    );

    await _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final point = LocationPoint.fromMap(event);
          _latest = point;
          _controller.add(point);
        }
      },
    );
  }

  @override
  Future<void> start() async {
    await _methodChannel.invokeMethod<void>('startTracking');
  }

  @override
  Future<void> stop() async {
    await _methodChannel.invokeMethod<void>('stopTracking');
  }

  @override
  Future<bool> isTracking() async {
    final result = await _methodChannel.invokeMethod<bool>('isTracking');
    return result ?? false;
  }

  @override
  Future<LocationPoint?> getCurrentLocation() async {
    if (_latest != null) {
      return _latest;
    }
    final result =
        await _methodChannel.invokeMapMethod<String, dynamic>('getCurrentLocation');
    if (result == null) {
      return null;
    }
    final point = LocationPoint.fromMap(result);
    _latest = point;
    return point;
  }

  Future<void> configureTerminatedPersistence(
    Map<String, dynamic> config,
  ) async {
    await _methodChannel.invokeMethod<void>(
      'configureTerminatedPersistence',
      config,
    );
  }

  Future<void> syncPersistenceState(LocationPoint point) async {
    await _methodChannel.invokeMethod<void>('syncPersistenceState', {
      'latitude': point.latitude,
      'longitude': point.longitude,
      'timestampMs': point.timestamp.millisecondsSinceEpoch,
    });
  }

  Future<bool> requestPermissions() async {
    final result = await _methodChannel.invokeMethod<bool>('requestPermissions');
    return result ?? false;
  }

  Future<bool> openBatteryOptimizationSettings() async {
    final result = await _methodChannel.invokeMethod<bool>(
      'openBatteryOptimizationSettings',
    );
    return result ?? false;
  }
}
