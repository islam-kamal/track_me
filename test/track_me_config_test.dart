import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/auth/admin_email_key.dart';
import 'package:track_me/firebase/database_targets.dart';

void main() {
  test('admin email keys replace dots so rules can look them up', () {
    expect(adminEmailKey('You@Gmail.com'), 'you@gmail,com');
  });

  test('location data uses the existing default database', () {
    expect(trackingDatabaseUrl, legacyDatabaseUrl);
    expect(trackingDatabaseUrl, contains('track-me-8e64a-default-rtdb'));
  });
}
