import 'package:flutter_test/flutter_test.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';

void main() {
  test('HttpTerminatedPersistenceConfig requires auth token', () {
    expect(
      () => const HttpTerminatedPersistenceConfig(
        endpointTemplate: 'https://api.example.com/{subjectId}',
        authToken: '',
      ).toMap(),
      throwsStateError,
    );
  });

  test('HttpTerminatedPersistenceConfig builds bearer headers', () {
    final map = const HttpTerminatedPersistenceConfig(
      endpointTemplate: 'https://api.example.com/{subjectId}',
      authToken: 'secret',
      collectorId: 'collector-1',
    ).toMap();

    expect(map['adapter'], 'http');
    expect(map['collectorId'], 'collector-1');
    expect(
      (map['headers'] as Map)['Authorization'],
      'Bearer secret',
    );
  });
}
