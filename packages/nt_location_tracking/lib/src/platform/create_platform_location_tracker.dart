import 'dart:io';

import 'ios_location_tracker.dart';
import 'native_location_tracker.dart';
import 'platform_location_tracker.dart';

/// Factory that selects the correct tracker per OS.
///
/// iOS uses flutter_background_geolocation (Dart) for force-quit survival.
/// Android uses a native foreground service bridged via MethodChannel/EventChannel.
PlatformLocationTracker createPlatformLocationTracker() {
  if (Platform.isIOS) {
    return IosLocationTracker();
  }
  if (Platform.isAndroid) {
    return NativeLocationTracker();
  }
  throw UnsupportedError(
    'Location tracking is only supported on iOS and Android.',
  );
}
