import 'package:flutter/widgets.dart';

import '../models/map_marker_data.dart';

/// Shared contract for map provider implementations (Google, OSM, future vendors).
///
/// Map UI talks only to this interface — switching providers requires no changes
/// outside the map module.
abstract class TrackingMapProvider {
  const TrackingMapProvider();

  Widget buildMap({
    required Key key,
    required List<MapMarkerData> markers,
    required MapMarkerData? currentLocation,
    required ValueChanged<MapMarkerData> onMarkerTap,
    required MapMarkerData? cameraTarget,
    required bool isLoading,
    required String? errorMessage,
    VoidCallback? onMapLoadFailed,
  });
}
