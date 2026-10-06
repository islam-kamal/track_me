import 'dart:io';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:permission_handler/permission_handler.dart';

/// Centralizes permission and battery prompts so host apps don't need
/// separate permission_handler wiring or manual settings buttons.
class LocationRuntimeRequirements {
  const LocationRuntimeRequirements._();

  /// Requests all permissions required for background tracking.
  ///
  /// iOS: Always/WhenInUse via BGL.
  /// Android: Fine → Background ("Allow all the time") → Notifications.
  static Future<bool> ensureLocationPermissions() async {
    if (Platform.isIOS) {
      final status = await bg.BackgroundGeolocation.requestPermission();
      return status == bg.ProviderChangeEvent.AUTHORIZATION_STATUS_ALWAYS ||
          status == bg.ProviderChangeEvent.AUTHORIZATION_STATUS_WHEN_IN_USE;
    }

    if (Platform.isAndroid) {
      // Step 1: Fine location (required before background can be requested).
      var fine = await Permission.location.status;
      if (!fine.isGranted) {
        fine = await Permission.location.request();
      }
      if (!fine.isGranted) {
        return false;
      }

      // Step 2: Background location — mandatory for foreground service tracking.
      if (await Permission.locationAlways.isDenied) {
        await Permission.locationAlways.request();
      }
      if (!await Permission.locationAlways.isGranted) {
        return false;
      }

      // Step 3: Notifications (Android 13+) for the tracking notification.
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      return true;
    }

    return true;
  }

  /// Prompts to disable battery optimization on Android.
  ///
  /// Many OEMs kill background services aggressively without this exemption.
  static Future<void> ensureBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) {
      return;
    }

    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) {
      return;
    }

    await Permission.ignoreBatteryOptimizations.request();
  }
}
