# Backend-Agnostic Architecture

## Migration Summary

| Current (before) | Backend dependency | Replacement contract |
| ---------------- | ------------------ | -------------------- |
| `LocationFirebaseWriter` (Dart) | Firebase RTDB | `LocationStorageDataSource` |
| `LocationFirebaseWriter` (Android Kotlin) | Firebase RTDB | Removed — persistence via Dart when engine runs |
| `LocationFirebaseWriter` (iOS Swift) | Firebase RTDB | Removed — persistence via Dart |
| `FirebaseLocationRepository` (example) | Firebase RTDB | `LocationHistoryDataSource` |
| `LocationTrackingConfig.database` | Firebase | Removed |
| `LocationTrackingConfig.firebaseDatabaseUrl` | Firebase | Removed |

## Architecture

```
Application
    │
    ├── nt_location_tracking_firebase (optional adapter)
    ├── location_tracking_rest (future)
    └── Custom adapter
            │
            ▼
    nt_location_tracking (core)
            │
    LocationTracking
    LocationPersistenceService
    Platform trackers (iOS / Android)
            │
    LocationStorageDataSource
    LocationHistoryDataSource
```

## Core contracts

### `LocationStorageDataSource`

Persists each tracked location. Implemented by the host app or an adapter package.

### `LocationHistoryDataSource`

Reads current location and history streams. Optional; used by UI layers.

### `LocationTrackingDependencies`

Bundle passed to `LocationTracking.initialize`.

## Initialization

```dart
await LocationTracking.initialize(
  config: LocationTrackingConfig(
    userId: 'subject_123',
    androidNotificationTitle: 'Tracking',
    androidNotificationText: 'Active',
  ),
  dependencies: LocationTrackingDependencies(
    storage: FirebaseLocationStorageDataSource(),
    history: FirebaseLocationHistoryDataSource(),
  ),
);
```

## Firebase adapter

See `packages/nt_location_tracking_firebase/`.

```yaml
dependencies:
  nt_location_tracking:
    path: ../
  nt_location_tracking_firebase:
    path: ../packages/nt_location_tracking_firebase
```

## Custom backend example

```dart
class CompanyTrackingDataSource implements LocationStorageDataSource {
  @override
  Future<void> saveLocation(
    LocationPoint point, {
    required String subjectId,
  }) async {
    await api.post('/users/$subjectId/locations', body: point.toMap());
  }
}
```

## Testing

Use `FakeLocationStorageDataSource` — no Firebase emulator required.

## Android note

When the Flutter engine is running, locations flow: native → EventChannel → Dart → `LocationStorageDataSource`.

When the app is **terminated**, Android saves directly from the foreground service using the terminated-persistence config from your adapter (`LocationTerminatedPersistenceProvider`). iOS uses a BGL headless Dart task with `configureHeadlessBootstrap`.
