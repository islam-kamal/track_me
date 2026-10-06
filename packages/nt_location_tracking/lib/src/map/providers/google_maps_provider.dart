import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/map_marker_data.dart';
import '../services/google_maps_initializer.dart';
import 'tracking_map_provider.dart';

/// Google Maps implementation of [TrackingMapProvider].
///
/// Requires a native API key (Android manifest / iOS AppDelegate) in addition
/// to the Dart-side key — see README. Catches platform errors and surfaces
/// them so the host can fall back to OSM.
class GoogleMapsProvider extends TrackingMapProvider {
  const GoogleMapsProvider();

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
    return _GoogleMapView(
      key: key,
      markers: markers,
      currentLocation: currentLocation,
      onMarkerTap: onMarkerTap,
      cameraTarget: cameraTarget,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onMapLoadFailed: onMapLoadFailed,
    );
  }
}

class _GoogleMapView extends StatefulWidget {
  const _GoogleMapView({
    required super.key,
    required this.markers,
    required this.currentLocation,
    required this.onMarkerTap,
    required this.cameraTarget,
    required this.isLoading,
    required this.errorMessage,
    this.onMapLoadFailed,
  });

  final List<MapMarkerData> markers;
  final MapMarkerData? currentLocation;
  final ValueChanged<MapMarkerData> onMarkerTap;
  final MapMarkerData? cameraTarget;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onMapLoadFailed;

  @override
  State<_GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<_GoogleMapView> {
  GoogleMapController? _controller;
  Set<Marker> _googleMarkers = const {};
  String? _loadError;
  bool Function(Object, StackTrace)? _previousPlatformErrorHandler;

  bool _isGoogleMapsPlatformError(Object error) {
    if (error is PlatformException) {
      final message = '${error.message ?? ''} ${error.details ?? ''}'.toLowerCase();
      return message.contains('api key') || message.contains('google maps');
    }
    return error.toString().toLowerCase().contains('api key');
  }

  void _handlePlatformError(Object error, StackTrace stack) {
    if (!mounted || !_isGoogleMapsPlatformError(error)) {
      return;
    }
    setState(() {
      _loadError =
          'Google Maps is unavailable. Add your API key to AndroidManifest.xml '
          'and local.properties, or enable OpenStreetMap.';
    });
    widget.onMapLoadFailed?.call();
  }

  @override
  void initState() {
    super.initState();
    _previousPlatformErrorHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      if (_loadError != null) {
        return true;
      }
      return _previousPlatformErrorHandler?.call(error, stack) ?? false;
    };
    _syncMarkers();
  }

  @override
  void dispose() {
    PlatformDispatcher.instance.onError = _previousPlatformErrorHandler;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _GoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMarkers();
    _moveCameraIfNeeded(oldWidget.cameraTarget, widget.cameraTarget);
  }

  void _syncMarkers() {
    final nextMarkers = <Marker>{};
    for (final marker in widget.markers) {
      nextMarkers.add(
        Marker(
          markerId: MarkerId(marker.id),
          position: LatLng(marker.latitude, marker.longitude),
          icon: marker.isCurrent
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => widget.onMarkerTap(marker),
          infoWindow: InfoWindow(
            title: marker.isCurrent ? 'Current location' : 'Tracked location',
            snippet: marker.address ?? 'Tap for details',
          ),
        ),
      );
    }
    setState(() => _googleMarkers = nextMarkers);
  }

  void _moveCameraIfNeeded(
    MapMarkerData? previousTarget,
    MapMarkerData? nextTarget,
  ) {
    if (_controller == null || nextTarget == null) {
      return;
    }
    if (previousTarget == nextTarget) {
      return;
    }
    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        cameraForMarkers(widget.markers, focus: nextTarget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorMessage ?? _loadError;
    if (error != null) {
      return _MapMessage(message: error);
    }

    final initialTarget = widget.cameraTarget ??
        widget.currentLocation ??
        (widget.markers.isNotEmpty ? widget.markers.last : null);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: cameraForMarkers(
            widget.markers,
            focus: initialTarget,
          ),
          markers: _googleMarkers,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          compassEnabled: true,
          onMapCreated: (controller) {
            _controller = controller;
            _syncMarkers();
          },
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

class _MapMessage extends StatelessWidget {
  const _MapMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
