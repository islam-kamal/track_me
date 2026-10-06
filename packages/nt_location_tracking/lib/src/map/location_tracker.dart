import 'package:flutter/material.dart';

import 'map_provider_type.dart';
import 'map_configuration.dart';
import '../models/location_point.dart';
import 'widgets/location_tracking_map.dart';

/// Host-facing map widget — wraps [LocationTrackingMap] with a simple API.
///
/// API key and provider flags come from the host app; the package never
/// embeds secrets. Builds [MapConfiguration] internally.
class LocationTracker extends StatelessWidget {
  const LocationTracker({
    super.key,
    this.googleMapsApiKey,
    this.enableGoogleMaps = false,
    this.enableOpenStreetMap = true,
    this.defaultProvider,
    this.currentLocation,
    this.locations = const [],
    this.height = 280,
    this.onProviderChanged,
  });

  final String? googleMapsApiKey;
  final bool enableGoogleMaps;
  final bool enableOpenStreetMap;
  final MapProviderType? defaultProvider;
  final LocationPoint? currentLocation;
  final List<LocationPoint> locations;
  final double height;
  final ValueChanged<MapProviderType>? onProviderChanged;

  MapConfiguration get _configuration {
    return MapConfiguration(
      googleMapsApiKey: googleMapsApiKey,
      enableGoogleMaps: enableGoogleMaps,
      enableOpenStreetMap: enableOpenStreetMap,
      defaultProvider: defaultProvider ?? MapProviderType.openStreetMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LocationTrackingMap(
      configuration: _configuration,
      currentLocation: currentLocation,
      locations: locations,
      height: height,
      onProviderChanged: onProviderChanged,
    );
  }
}
