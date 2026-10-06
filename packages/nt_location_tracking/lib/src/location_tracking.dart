import 'dart:async';
import 'dart:io';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

import 'config/location_tracking_config.dart';
import 'contracts/location_storage_data_source.dart';
import 'contracts/location_terminated_persistence.dart';
import 'contracts/location_tracking_dependencies.dart';
import 'exceptions/tracking_exception.dart';
import 'headless/location_tracking_headless.dart';
import 'headless/terminated_persistence_store.dart';
import 'models/location_permission_exception.dart';
import 'models/location_point.dart';
import 'platform/create_platform_location_tracker.dart';
import 'platform/location_runtime_requirements.dart';
import 'platform/native_location_tracker.dart';
import 'platform/platform_location_tracker.dart';
import 'services/location_persistence_policy.dart';
import 'services/location_persistence_service.dart';

/// Main facade for the location tracking plugin.
///
/// Responsibilities:
/// - Pick the correct native tracker (iOS BGL vs Android foreground service)
/// - Forward location updates to [LocationPersistenceService]
/// - Handle permissions and battery settings before tracking starts
///
/// The plugin never talks to Firebase/REST directly — that is the host app's
/// job via [LocationTrackingDependencies.storage].
class LocationTracking {
  LocationTracking._();

  /// Platform-specific tracker created once at startup.
  static final PlatformLocationTracker _tracker =
      createPlatformLocationTracker();

  static LocationTrackingConfig? _config;
  static LocationTrackingDependencies? _dependencies;

  static final TerminatedPersistenceStore _terminatedStore =
      TerminatedPersistenceStore();

  /// Bridges location stream → backend storage contract.
  static LocationPersistenceService? _persistence;

  /// Throttles backend saves using [LocationTrackingConfig] interval + distance.
  static LocationPersistencePolicy? _persistencePolicy;

  /// Flushes the latest location on a timer when the device has not moved.
  static Timer? _periodicPersistTimer;

  /// Prevents overlapping saves when a GPS event and timer fire together.
  static bool _persistInFlight = false;

  /// Keeps storage in sync for every location emitted by the native layer.
  static StreamSubscription<LocationPoint>? _persistenceSubscription;

  /// Notifies the host app when a location could not be saved to the backend.
  ///
  /// The native tracker keeps running — only persistence failed for that point.
  static final StreamController<TrackingException>
  _persistenceErrorsController =
      StreamController<TrackingException>.broadcast();

  /// Stream of backend persistence failures (network, auth, etc.).
  ///
  /// Subscribe to handle retries, user messaging, or logging. Tracking and
  /// [onLocation] continue after errors; a failed save does not stop the stream.
  static Stream<TrackingException> get onPersistenceError =>
      _persistenceErrorsController.stream;

  /// Rebuilds [LocationTrackingDependencies] in BGL headless isolates (iOS).
  ///
  /// Call from `main()` before [registerHeadlessTask]:
  /// ```dart
  /// LocationTracking.configureHeadlessBootstrap(() async {
  ///   await Firebase.initializeApp();
  ///   return myDependencies;
  /// });
  /// ```
  static void configureHeadlessBootstrap(
    LocationHeadlessBootstrap bootstrap,
  ) {
    locationTrackingHeadlessBootstrap = bootstrap;
  }

  /// Registers the BGL headless task for persistence when the app is terminated.
  ///
  /// Must be called from `main()` before `runApp`, after
  /// [configureHeadlessBootstrap].
  static Future<void> registerHeadlessTask() async {
    if (!Platform.isIOS) {
      return;
    }
    await bg.BackgroundGeolocation.registerHeadlessTask(
      ntLocationTrackingHeadlessTask,
    );
  }

  /// Re-pushes terminated persistence config to native Android / shared prefs.
  ///
  /// Call after login when the auth token or collector id becomes available,
  /// and again after [start] if the token was refreshed.
  static Future<void> refreshTerminatedPersistence() async {
    _ensureInitialized();
    final config = _config!;
    final storage = _dependencies!.storage;
    await _configureTerminatedPersistence(config, storage);
    final tracking = await _tracker.isTracking();
    await _syncTerminatedTrackingState(isTracking: tracking);
  }

  /// Wires configuration, backend adapters, and the platform tracker.
  ///
  /// Must be called once before [start]. The [dependencies.storage] implementation
  /// is provided by the host app (Firebase adapter, REST client, etc.).
  static Future<void> initialize({
    required LocationTrackingConfig config,
    required LocationTrackingDependencies dependencies,
  }) async {
    _config = config;
    _dependencies = dependencies;

    // Persistence is decoupled from platform code so any backend can be plugged in.
    _persistence = LocationPersistenceService(
      storage: dependencies.storage,
      subjectId: config.userId,
    );
    _persistencePolicy = LocationPersistencePolicy(
      intervalSeconds: config.intervalSeconds,
      distanceFilterMeters: config.distanceFilterMeters,
    )..reset();

    await _tracker.initialize(config);
    await _configureTerminatedPersistence(config, dependencies.storage);
    await _syncTerminatedTrackingState(isTracking: false);

    _stopPeriodicPersistTimer();
    // Re-subscribe on re-init to avoid duplicate listeners.
    await _persistenceSubscription?.cancel();
    _persistenceSubscription = _tracker.onLocation.listen(
      _onLocationReceived,
      onError: _handleLocationStreamError,
      cancelOnError: false,
    );
  }

  static void _startPeriodicPersistTimer() {
    _stopPeriodicPersistTimer();
    final seconds = _config?.intervalSeconds ?? 30;
    if (seconds <= 0) {
      return;
    }

    _periodicPersistTimer = Timer.periodic(
      Duration(seconds: seconds),
      (_) => _onPeriodicPersistTick(),
    );
  }

  static void _stopPeriodicPersistTimer() {
    _periodicPersistTimer?.cancel();
    _periodicPersistTimer = null;
  }

  static void _onPeriodicPersistTick() {
    final policy = _persistencePolicy;
    if (policy == null) {
      return;
    }

    final point = policy.pendingPeriodicSave();
    if (point == null) {
      return;
    }

    unawaited(
      _persistLocation(point).catchError(
        (Object error, StackTrace stackTrace) =>
            _handlePersistenceFailure(error, stackTrace),
      ),
    );
  }

  /// Handles each location from the native layer. Backend saves are throttled
  /// by [LocationTrackingConfig.intervalSeconds] and [distanceFilterMeters].
  static void _onLocationReceived(LocationPoint point) {
    final policy = _persistencePolicy;
    if (policy == null) {
      return;
    }

    policy.onLocationReceived(point);
    if (!policy.shouldPersist(point)) {
      return;
    }

    unawaited(
      _persistLocation(point).catchError(
        (Object error, StackTrace stackTrace) =>
            _handlePersistenceFailure(error, stackTrace),
      ),
    );
  }

  static void _handleLocationStreamError(Object error, StackTrace stackTrace) {
    _handlePersistenceFailure(error, stackTrace);
  }

  static void _handlePersistenceFailure(Object error, StackTrace _) {
    final trackingError = error is TrackingException
        ? error
        : NetworkException('Failed to persist location.', cause: error);
    if (!_persistenceErrorsController.isClosed) {
      _persistenceErrorsController.add(trackingError);
    }
  }

  /// Starts tracking after permissions (and Android battery exemption) are granted.
  static Future<void> start() async {
    _ensureInitialized();

    // Permissions are requested here — not left to the host UI — so tracking
    // always fails safely with [LocationPermissionException] when denied.
    final granted = await requestPermissions();
    if (!granted) {
      throw const LocationPermissionException(
        'Location permissions are required to start tracking.',
      );
    }

    // OEM battery savers kill background services; prompt exemption on Android.
    await ensureBatteryOptimizationExemption();
    _startPeriodicPersistTimer();
    await _syncTerminatedTrackingState(isTracking: true);
    await _tracker.start();
  }

  static Future<void> stop({bool flush = true}) async {
    _ensureInitialized();
    _stopPeriodicPersistTimer();
    if (flush) {
      await _flushLocationOnStop();
    }
    await _syncTerminatedTrackingState(isTracking: false);
    await _tracker.stop();
  }

  /// Persists the latest known location before tracking stops.
  ///
  /// Bypasses interval/distance throttling so the backend receives a final
  /// position even when the last GPS update was not yet due for a periodic save.
  static Future<void> _flushLocationOnStop() async {
    while (_persistInFlight) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }

    final policy = _persistencePolicy;
    var point = policy?.latestLocation;
    point ??= await _tracker.getCurrentLocation();
    if (point == null) {
      return;
    }

    policy?.onLocationReceived(point);
    if (policy != null && !policy.needsFlushOnStop()) {
      return;
    }

    try {
      await _persistLocation(point, force: true);
    } catch (error, stackTrace) {
      _handlePersistenceFailure(error, stackTrace);
    }
  }

  static Future<bool> isTracking() {
    _ensureInitialized();
    return _tracker.isTracking();
  }

  /// Live location stream while the Flutter engine is running.
  ///
  /// When the app is terminated, native Android persistence and iOS headless
  /// tasks continue saving via the configured backend adapter.
  static Stream<LocationPoint> get onLocation {
    _ensureInitialized();
    return _tracker.onLocation;
  }

  static Future<LocationPoint?> getCurrentLocation() {
    _ensureInitialized();
    return _tracker.getCurrentLocation();
  }

  /// Exposes injected adapters (e.g. history reader for UI screens).
  static LocationTrackingDependencies get dependencies {
    _ensureInitialized();
    return _dependencies!;
  }

  static Future<bool> requestPermissions() {
    return LocationRuntimeRequirements.ensureLocationPermissions();
  }

  static Future<void> ensureBatteryOptimizationExemption() {
    return LocationRuntimeRequirements.ensureBatteryOptimizationExemption();
  }

  static Future<bool> openBatteryOptimizationSettings() async {
    if (Platform.isAndroid && _tracker is NativeLocationTracker) {
      return (_tracker as NativeLocationTracker)
          .openBatteryOptimizationSettings();
    }
    return false;
  }

  static Future<void> _persistLocation(
    LocationPoint point, {
    bool force = false,
  }) async {
    if (_persistInFlight) {
      if (!force) {
        return;
      }
      while (_persistInFlight) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    }

    _persistInFlight = true;
    try {
      final pointToSave = _shouldIncludeAddressInSave(point)
          ? point
          : point.withoutAddress();
      await _persistence?.persist(pointToSave);
      _persistencePolicy?.markPersisted(point);
      await _syncPersistenceState(point);
    } finally {
      _persistInFlight = false;
    }
  }

  static bool _shouldIncludeAddressInSave(LocationPoint point) {
    return _config?.enableReverseGeocoding ?? false;
  }

  static Future<void> _configureTerminatedPersistence(
    LocationTrackingConfig config,
    LocationStorageDataSource storage,
  ) async {
    Map<String, dynamic>? terminatedMap;
    if (storage is LocationTerminatedPersistenceProvider) {
      terminatedMap =
          (storage as LocationTerminatedPersistenceProvider)
              .toTerminatedPersistenceMap();
    }

    await _terminatedStore.saveTrackingConfig(
      userId: config.userId,
      intervalSeconds: config.intervalSeconds,
      distanceFilterMeters: config.distanceFilterMeters,
      isTracking: false,
      enableReverseGeocoding: config.enableReverseGeocoding,
      terminatedPersistence: terminatedMap,
    );

    if (Platform.isAndroid && terminatedMap != null) {
      final tracker = _tracker;
      if (tracker is NativeLocationTracker) {
        await tracker.configureTerminatedPersistence(terminatedMap);
      }
    }
  }

  static Future<void> _syncTerminatedTrackingState({
    required bool isTracking,
  }) async {
    final config = _config;
    if (config == null) {
      return;
    }

    final storage = _dependencies?.storage;
    Map<String, dynamic>? terminatedMap;
    final provider = storage;
    if (provider is LocationTerminatedPersistenceProvider) {
      terminatedMap =
          (provider as LocationTerminatedPersistenceProvider)
              .toTerminatedPersistenceMap();
    }

    await _terminatedStore.saveTrackingConfig(
      userId: config.userId,
      intervalSeconds: config.intervalSeconds,
      distanceFilterMeters: config.distanceFilterMeters,
      isTracking: isTracking,
      enableReverseGeocoding: config.enableReverseGeocoding,
      terminatedPersistence: terminatedMap,
    );

    if (Platform.isAndroid && terminatedMap != null) {
      final tracker = _tracker;
      if (tracker is NativeLocationTracker) {
        await tracker.configureTerminatedPersistence(terminatedMap);
      }
    }
  }

  static Future<void> _syncPersistenceState(LocationPoint point) async {
    final policy = _persistencePolicy;
    if (policy != null) {
      await _terminatedStore.savePolicyState(policy);
    }

    if (Platform.isAndroid && _tracker is NativeLocationTracker) {
      await (_tracker as NativeLocationTracker).syncPersistenceState(point);
    }
  }

  static void _ensureInitialized() {
    if (_config == null || _dependencies == null) {
      throw StateError(
        'LocationTracking.initialize must be called with dependencies '
        'before using the tracker.',
      );
    }
  }
}
