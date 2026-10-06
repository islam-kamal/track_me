import 'location_history_data_source.dart';
import 'location_storage_data_source.dart';

/// Backend implementations injected by the host application at startup.
///
/// Passed to [LocationTracking.initialize] so the plugin never instantiates
/// Firebase, HTTP clients, or other SDKs internally.
class LocationTrackingDependencies {
  const LocationTrackingDependencies({
    required this.storage,
    this.history,
  });

  /// Required — saves each tracked location.
  final LocationStorageDataSource storage;

  /// Optional — reads locations for UI (history screen, live map markers).
  final LocationHistoryDataSource? history;
}
