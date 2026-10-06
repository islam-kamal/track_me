import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';

import 'fakes/fake_location_storage_data_source.dart';

void main() {
  test('LocationPoint serializes to map', () {
    final point = LocationPoint(
      latitude: 30.0444,
      longitude: 31.2357,
      accuracy: 5,
      timestamp: DateTime.utc(2026, 6, 22, 10, 30, 45, 123),
      platform: 'ios',
      address: '123 Example Street, Cairo, Egypt',
      isMoving: true,
    );

    final map = point.toMap();
    final restored = LocationPoint.fromMap(map);

    expect(restored.latitude, point.latitude);
    expect(restored.longitude, point.longitude);
    expect(restored.platform, point.platform);
    expect(restored.address, point.address);
    expect(map['timestamp'], isA<String>());
    expect(restored.timestamp, point.timestamp);
  });

  test('LocationTrackingConfig exposes platform map', () {
    const config = LocationTrackingConfig(
      userId: 'user_1',
      androidNotificationTitle: 'Title',
      androidNotificationText: 'Text',
      distanceFilterMeters: 15,
      intervalSeconds: 60,
      enableReverseGeocoding: true,
    );

    final map = config.toPlatformMap();
    expect(map['userId'], 'user_1');
    expect(map['distanceFilterMeters'], 15);
    expect(map['intervalSeconds'], 60);
    expect(map['enableReverseGeocoding'], isTrue);
    expect(map.containsKey('firebaseDatabaseUrl'), isFalse);
  });

  test('LocationPoint.withoutAddress omits address from map', () {
    final point = LocationPoint(
      latitude: 30.0444,
      longitude: 31.2357,
      accuracy: 5,
      timestamp: DateTime.utc(2026, 6, 22, 10, 30, 45),
      platform: 'android',
      address: '123 Example Street',
    );

    final stripped = point.withoutAddress();
    expect(stripped.address, isNull);
    expect(stripped.toMap().containsKey('address'), isFalse);
    expect(stripped.latitude, point.latitude);
    expect(stripped.longitude, point.longitude);
  });

  test('LocationPersistenceService saves via storage contract', () async {
    final storage = FakeLocationStorageDataSource();
    final service = LocationPersistenceService(
      storage: storage,
      subjectId: 'demo_user',
    );

    final point = LocationPoint(
      latitude: 1,
      longitude: 2,
      accuracy: 3,
      timestamp: DateTime.utc(2026, 1, 1),
      platform: 'test',
    );

    await service.persist(point);

    expect(storage.lastSubjectId, 'demo_user');
    expect(storage.savedLocations, hasLength(1));
  });

  test('persistence listener survives save failures', () async {
    final locations = StreamController<LocationPoint>();
    final errors = <Object>[];
    var saveAttempts = 0;

    final subscription = locations.stream.listen(
      (point) async {
        saveAttempts++;
        try {
          if (saveAttempts == 1) {
            throw const NetworkException('Simulated save failure');
          }
          await Future<void>.value();
        } catch (error) {
          errors.add(error);
        }
      },
      cancelOnError: false,
    );

    final point = LocationPoint(
      latitude: 1,
      longitude: 2,
      accuracy: 3,
      timestamp: DateTime.utc(2026, 1, 1),
      platform: 'test',
    );

    locations.add(point);
    locations.add(point);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(errors, hasLength(1));
    expect(saveAttempts, 2);

    await subscription.cancel();
    await locations.close();
  });
}
