import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import '../models/map_marker_data.dart';

/// Prepares Google Maps before the first map widget is rendered.
///
/// The host app must still provide the API key natively:
/// - Android: `AndroidManifest.xml` meta-data `com.google.android.geo.API_KEY`
/// - iOS: `GMSServices.provideAPIKey(...)` in `AppDelegate`
class GoogleMapsInitializer {
  const GoogleMapsInitializer._();

  static bool _initialized = false;

  static Future<void> initialize({required String? apiKey}) async {
    if (_initialized || apiKey == null || apiKey.trim().isEmpty) {
      return;
    }

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    if (Platform.isAndroid) {
      final platform = GoogleMapsFlutterPlatform.instance;
      if (platform is GoogleMapsFlutterAndroid) {
        await platform.initializeWithRenderer(AndroidMapRenderer.latest);
      }
    }

    _initialized = true;
  }
}

CameraPosition cameraForMarkers(
  List<MapMarkerData> markers, {
  MapMarkerData? focus,
}) {
  final target = focus ?? (markers.isNotEmpty ? markers.last : null);
  if (target == null) {
    return const CameraPosition(target: LatLng(0, 0), zoom: 2);
  }
  return CameraPosition(
    target: LatLng(target.latitude, target.longitude),
    zoom: focus?.isCurrent == true ? 16 : 14,
  );
}
