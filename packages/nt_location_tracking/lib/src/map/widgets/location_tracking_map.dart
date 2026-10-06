import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/location_point.dart';
import '../geocoding/address_resolver.dart';
import '../map_configuration.dart';
import '../map_provider_type.dart';
import '../models/map_marker_data.dart';
import '../providers/google_maps_provider.dart';
import '../providers/open_street_map_provider.dart';
import '../providers/tracking_map_provider.dart';
import '../services/google_maps_initializer.dart';
import 'marker_details_sheet.dart';

/// Internal map widget — provider toggle, marker rendering, tap → bottom sheet.
///
/// Keeps Google/OSM selection and [AddressResolver] here so [LocationTracker]
/// stays a thin public wrapper.
class LocationTrackingMap extends StatefulWidget {
  const LocationTrackingMap({
    super.key,
    required this.configuration,
    this.currentLocation,
    this.locations = const [],
    this.height = 280,
    this.onProviderChanged,
  });

  final MapConfiguration configuration;
  final LocationPoint? currentLocation;
  final List<LocationPoint> locations;
  final double height;
  final ValueChanged<MapProviderType>? onProviderChanged;

  @override
  State<LocationTrackingMap> createState() => _LocationTrackingMapState();
}

class _LocationTrackingMapState extends State<LocationTrackingMap> {
  final AddressResolver _addressResolver = AddressResolver();
  MapProviderType? _selectedProvider;
  MapMarkerData? _cameraTarget;
  bool _initializingGoogleMaps = false;
  String? _mapError;

  static const _googleProvider = GoogleMapsProvider();
  static const _osmProvider = OpenStreetMapProvider();

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.configuration.resolvedDefaultProvider;
    unawaited(_initializeProviders());
  }

  @override
  void didUpdateWidget(covariant LocationTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.configuration != widget.configuration) {
      _selectedProvider = widget.configuration.resolvedDefaultProvider;
      unawaited(_initializeProviders());
    }
    final nextTarget = _currentMarker();
    if (nextTarget != null && nextTarget != _cameraTarget) {
      _cameraTarget = nextTarget;
    }
  }

  bool _googleMapsDisabled = false;

  void _handleGoogleMapsLoadFailed() {
    if (!widget.configuration.isOpenStreetMapAvailable) {
      setState(() {
        _mapError =
            'Google Maps failed to load. Enable OpenStreetMap or configure '
            'your native Google Maps API key.';
      });
      return;
    }
    setState(() {
      _googleMapsDisabled = true;
      _selectedProvider = MapProviderType.openStreetMap;
      _mapError = null;
    });
    widget.onProviderChanged?.call(MapProviderType.openStreetMap);
  }

  Future<void> _initializeProviders() async {
    if (!widget.configuration.isGoogleMapsAvailable) {
      return;
    }
    setState(() {
      _initializingGoogleMaps = true;
      _mapError = null;
    });
    try {
      await GoogleMapsInitializer.initialize(
        apiKey: widget.configuration.googleMapsApiKey,
      );
    } catch (error) {
      _mapError = 'Google Maps failed to initialize: $error';
    } finally {
      if (mounted) {
        setState(() => _initializingGoogleMaps = false);
      }
    }
  }

  List<MapMarkerData> _buildMarkers() {
    final markers = <MapMarkerData>[];
    final current = widget.currentLocation;
    if (current != null) {
      markers.add(
        MapMarkerData.fromLocationPoint(
          current,
          id: 'current',
          isCurrent: true,
        ),
      );
      _addressResolver.seed(
        current.address,
        latitude: current.latitude,
        longitude: current.longitude,
      );
    }

    for (var index = 0; index < widget.locations.length; index++) {
      final point = widget.locations[index];
      if (current != null &&
          point.latitude == current.latitude &&
          point.longitude == current.longitude &&
          point.timestamp == current.timestamp) {
        continue;
      }
      markers.add(
        MapMarkerData.fromLocationPoint(
          point,
          id: 'history_${index}_${point.timestamp.millisecondsSinceEpoch}',
        ),
      );
      _addressResolver.seed(
        point.address,
        latitude: point.latitude,
        longitude: point.longitude,
      );
    }
    return markers;
  }

  MapMarkerData? _currentMarker() {
    final current = widget.currentLocation;
    if (current == null) {
      return null;
    }
    return MapMarkerData.fromLocationPoint(
      current,
      id: 'current',
      isCurrent: true,
    );
  }

  TrackingMapProvider _providerFor(MapProviderType type) {
    return switch (type) {
      MapProviderType.google => _googleProvider,
      MapProviderType.openStreetMap => _osmProvider,
    };
  }

  Future<void> _handleMarkerTap(MapMarkerData marker) async {
    if (!mounted) {
      return;
    }
    setState(() => _cameraTarget = marker);

    final address = await _addressResolver.resolve(
      latitude: marker.latitude,
      longitude: marker.longitude,
      existingAddress: marker.address,
    );
    if (!mounted) {
      return;
    }
    await showMarkerDetailsSheet(
      context,
      marker: marker,
      address: address,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.configuration.showMapSection) {
      return const SizedBox.shrink();
    }

    final providers = widget.configuration.availableProviders
        .where(
          (provider) =>
              provider != MapProviderType.google || !_googleMapsDisabled,
        )
        .toList(growable: false);
    if (providers.isEmpty) {
      return const SizedBox.shrink();
    }
    final selected = providers.contains(_selectedProvider)
        ? _selectedProvider!
        : providers.first;
    _selectedProvider = selected;

    final markers = _buildMarkers();
    final cameraTarget = _cameraTarget ?? _currentMarker() ?? markers.lastOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (providers.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<MapProviderType>(
              segments: [
                if (widget.configuration.isGoogleMapsAvailable &&
                    !_googleMapsDisabled)
                  const ButtonSegment(
                    value: MapProviderType.google,
                    label: Text('Google Maps'),
                  ),
                if (widget.configuration.isOpenStreetMapAvailable)
                  const ButtonSegment(
                    value: MapProviderType.openStreetMap,
                    label: Text('OpenStreetMap'),
                  ),
              ],
              selected: {selected},
              onSelectionChanged: (selection) {
                final provider = selection.first;
                setState(() => _selectedProvider = provider);
                widget.onProviderChanged?.call(provider);
              },
            ),
          ),
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _providerFor(selected).buildMap(
              key: ValueKey(selected),
              markers: markers,
              currentLocation: _currentMarker(),
              onMarkerTap: _handleMarkerTap,
              cameraTarget: cameraTarget,
              isLoading: _initializingGoogleMaps,
              errorMessage: selected == MapProviderType.google ? _mapError : null,
              onMapLoadFailed: selected == MapProviderType.google
                  ? _handleGoogleMapsLoadFailed
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

extension _LastOrNull<E> on List<E> {
  E? get lastOrNull => isEmpty ? null : last;
}
