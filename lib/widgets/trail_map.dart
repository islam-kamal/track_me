import 'package:flutter/material.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';

class TrailMap extends StatelessWidget {
  const TrailMap({
    super.key,
    this.currentLocation,
    this.locations = const [],
  });

  final LocationPoint? currentLocation;
  final List<LocationPoint> locations;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        return LocationTracker(
          enableOpenStreetMap: true,
          enableGoogleMaps: false,
          defaultProvider: MapProviderType.openStreetMap,
          currentLocation: currentLocation,
          locations: locations,
          height: height,
        );
      },
    );
  }
}
