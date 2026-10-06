import 'map_provider_type.dart';

/// Feature flags and API key settings for the map layer.
///
/// Google Maps is auto-disabled when [googleMapsApiKey] is empty, so host apps
/// can ship OSM-only builds without code changes.
class MapConfiguration {
  const MapConfiguration({
    this.googleMapsApiKey,
    this.enableGoogleMaps = false,
    this.enableOpenStreetMap = true,
    this.defaultProvider = MapProviderType.openStreetMap,
  });

  /// Google Maps API key supplied by the host application.
  ///
  /// Never hardcode this value inside the package.
  final String? googleMapsApiKey;

  /// Enables Google Maps when a non-empty [googleMapsApiKey] is provided.
  final bool enableGoogleMaps;

  /// Enables OpenStreetMap via [flutter_map].
  final bool enableOpenStreetMap;

  /// Preferred provider when multiple providers are enabled.
  final MapProviderType defaultProvider;

  bool get hasGoogleMapsApiKey =>
      googleMapsApiKey != null && googleMapsApiKey!.trim().isNotEmpty;

  bool get isGoogleMapsAvailable => enableGoogleMaps && hasGoogleMapsApiKey;

  bool get isOpenStreetMapAvailable => enableOpenStreetMap;

  bool get showMapSection => isGoogleMapsAvailable || isOpenStreetMapAvailable;

  List<MapProviderType> get availableProviders {
    final providers = <MapProviderType>[];
    if (isGoogleMapsAvailable) {
      providers.add(MapProviderType.google);
    }
    if (isOpenStreetMapAvailable) {
      providers.add(MapProviderType.openStreetMap);
    }
    return providers;
  }

  MapProviderType? get resolvedDefaultProvider {
    if (!showMapSection) {
      return null;
    }
    if (defaultProvider == MapProviderType.google && isGoogleMapsAvailable) {
      return MapProviderType.google;
    }
    if (defaultProvider == MapProviderType.openStreetMap &&
        isOpenStreetMapAvailable) {
      return MapProviderType.openStreetMap;
    }
    return availableProviders.firstOrNull;
  }

  MapConfiguration copyWith({
    String? googleMapsApiKey,
    bool? enableGoogleMaps,
    bool? enableOpenStreetMap,
    MapProviderType? defaultProvider,
  }) {
    return MapConfiguration(
      googleMapsApiKey: googleMapsApiKey ?? this.googleMapsApiKey,
      enableGoogleMaps: enableGoogleMaps ?? this.enableGoogleMaps,
      enableOpenStreetMap: enableOpenStreetMap ?? this.enableOpenStreetMap,
      defaultProvider: defaultProvider ?? this.defaultProvider,
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
