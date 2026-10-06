import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../models/map_marker_data.dart';
import 'tracking_map_provider.dart';

/// OpenStreetMap tiles via [flutter_map] — no API key required.
///
/// Used as default/fallback when Google Maps is disabled or fails to initialize.
class OpenStreetMapProvider extends TrackingMapProvider {
  const OpenStreetMapProvider();

  @override
  Widget buildMap({
    required Key key,
    required List<MapMarkerData> markers,
    required MapMarkerData? currentLocation,
    required ValueChanged<MapMarkerData> onMarkerTap,
    required MapMarkerData? cameraTarget,
    required bool isLoading,
    required String? errorMessage,
    VoidCallback? onMapLoadFailed,
  }) {
    return _OpenStreetMapView(
      key: key,
      markers: markers,
      currentLocation: currentLocation,
      onMarkerTap: onMarkerTap,
      cameraTarget: cameraTarget,
      isLoading: isLoading,
      errorMessage: errorMessage,
    );
  }
}

class _OpenStreetMapView extends StatefulWidget {
  const _OpenStreetMapView({
    required super.key,
    required this.markers,
    required this.currentLocation,
    required this.onMarkerTap,
    required this.cameraTarget,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<MapMarkerData> markers;
  final MapMarkerData? currentLocation;
  final ValueChanged<MapMarkerData> onMarkerTap;
  final MapMarkerData? cameraTarget;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<_OpenStreetMapView> createState() => _OpenStreetMapViewState();
}

class _OpenStreetMapViewState extends State<_OpenStreetMapView> {
  final MapController _controller = MapController();
  MapMarkerData? _lastCameraTarget;

  @override
  void didUpdateWidget(covariant _OpenStreetMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _moveCameraIfNeeded(widget.cameraTarget);
  }

  void _moveCameraIfNeeded(MapMarkerData? target) {
    if (target == null || target == _lastCameraTarget) {
      return;
    }
    _lastCameraTarget = target;
    _controller.move(
      latlng.LatLng(target.latitude, target.longitude),
      target.isCurrent ? 16 : 14,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(widget.errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    final focus = widget.cameraTarget ??
        widget.currentLocation ??
        (widget.markers.isNotEmpty ? widget.markers.last : null);
    final center = focus == null
        ? const latlng.LatLng(0, 0)
        : latlng.LatLng(focus.latitude, focus.longitude);
    final zoom = focus?.isCurrent == true ? 16.0 : 14.0;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: center,
            initialZoom: focus == null ? 2 : zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.nt_location_tracking',
            ),
            MarkerLayer(
              markers: widget.markers
                  .map(
                    (marker) => Marker(
                      point: latlng.LatLng(marker.latitude, marker.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => widget.onMarkerTap(marker),
                        child: Icon(
                          Icons.location_on,
                          color: marker.isCurrent ? Colors.blue : Colors.red,
                          size: marker.isCurrent ? 40 : 32,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'osm_zoom_in',
                onPressed: () {
                  final camera = _controller.camera;
                  _controller.move(camera.center, camera.zoom + 1);
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'osm_zoom_out',
                onPressed: () {
                  final camera = _controller.camera;
                  _controller.move(camera.center, camera.zoom - 1);
                },
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
        if (widget.isLoading)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(minHeight: 3),
          ),
      ],
    );
  }
}
