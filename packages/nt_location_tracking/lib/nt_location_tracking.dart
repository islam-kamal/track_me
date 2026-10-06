/// Public API surface for the nt_location_tracking plugin.
///
/// Export only stable types that host applications need.
/// Internal implementation details stay under `src/`.
library;

export 'src/config/location_tracking_config.dart';
export 'src/contracts/location_history_data_source.dart';
export 'src/contracts/http_terminated_persistence_config.dart';
export 'src/contracts/location_storage_data_source.dart';
export 'src/contracts/location_terminated_persistence.dart';
export 'src/contracts/location_tracking_dependencies.dart';
export 'src/exceptions/tracking_exception.dart';
export 'src/headless/location_tracking_headless.dart';
export 'src/location_tracking.dart';
export 'src/services/location_persistence_service.dart';
export 'src/map/location_tracker.dart';
export 'src/map/map_configuration.dart';
export 'src/map/map_provider_type.dart';
export 'src/map/widgets/location_tracking_map.dart';
export 'src/models/location_permission_exception.dart';
export 'src/models/location_point.dart';
