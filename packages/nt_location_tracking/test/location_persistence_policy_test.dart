import 'package:flutter_test/flutter_test.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';

import 'package:nt_location_tracking/src/services/location_persistence_policy.dart';

void main() {
  group('LocationPersistencePolicy', () {
    late LocationPersistencePolicy policy;

    setUp(() {
      policy = LocationPersistencePolicy(
        intervalSeconds: 60,
        distanceFilterMeters: 100,
      );
    });

    test('persists first location immediately', () {
      final point = _point(lat: 30, lng: 31);
      policy.onLocationReceived(point);

      expect(policy.shouldPersist(point), isTrue);
    });

    test('skips save when within distance and interval', () {
      final first = _point(lat: 30, lng: 31);
      final nearby = _point(lat: 30.0001, lng: 31.0001);
      final now = DateTime.utc(2026, 1, 1, 12, 0, 0);

      policy.onLocationReceived(first);
      policy.markPersisted(first, at: now);
      policy.onLocationReceived(nearby);

      expect(
        policy.shouldPersist(nearby, now: now.add(const Duration(seconds: 10))),
        isFalse,
      );
    });

    test('persists when distance threshold exceeded', () {
      final first = _point(lat: 30, lng: 31);
      final moved = _point(lat: 30.002, lng: 31);
      final now = DateTime.utc(2026, 1, 1, 12, 0, 0);

      policy.onLocationReceived(first);
      policy.markPersisted(first, at: now);
      policy.onLocationReceived(moved);

      expect(
        policy.shouldPersist(moved, now: now.add(const Duration(seconds: 5))),
        isTrue,
      );
    });

    test('persists on interval even without movement', () {
      final first = _point(lat: 30, lng: 31);
      final same = _point(lat: 30, lng: 31);
      final now = DateTime.utc(2026, 1, 1, 12, 0, 0);

      policy.onLocationReceived(first);
      policy.markPersisted(first, at: now);
      policy.onLocationReceived(same);

      expect(policy.shouldPersist(same, now: now.add(const Duration(seconds: 59))),
          isFalse);
      expect(policy.shouldPersist(same, now: now.add(const Duration(seconds: 60))),
          isTrue);
      expect(
        policy.pendingPeriodicSave(now: now.add(const Duration(seconds: 60))),
        same,
      );
    });

    test('needsFlushOnStop when latest was throttled', () {
      final saved = _point(lat: 30, lng: 31);
      final unsaved = _point(lat: 30.0005, lng: 31.0005);
      final now = DateTime.utc(2026, 1, 1, 12, 0, 0);

      policy.onLocationReceived(saved);
      policy.markPersisted(saved, at: now);
      policy.onLocationReceived(unsaved);

      expect(policy.shouldPersist(unsaved, now: now), isFalse);
      expect(policy.needsFlushOnStop(), isTrue);
    });

    test('does not need flush when latest already persisted', () {
      final point = _point(lat: 30, lng: 31);
      policy.onLocationReceived(point);
      policy.markPersisted(point);

      expect(policy.needsFlushOnStop(), isFalse);
    });
  });
}

LocationPoint _point({required double lat, required double lng}) {
  return LocationPoint(
    latitude: lat,
    longitude: lng,
    accuracy: 5,
    timestamp: DateTime.utc(2026, 1, 1),
    platform: 'test',
  );
}
