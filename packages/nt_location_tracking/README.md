# Location Tracking

A production-ready Flutter plugin for **continuous location tracking** on iOS and Android, with **pluggable backend storage**, **configurable maps** (Google Maps + OpenStreetMap), and **reverse geocoding**.

The core package contains **business logic only** — no Firebase, REST, or HTTP dependencies. Your app supplies the backend through simple interfaces.

---

## Table of Contents

1. [Advantages](#advantages)
2. [Package Structure](#package-structure)
3. [How Every Part Works](#how-every-part-works)
4. [How to Use](#how-to-use)
5. [Maps](#maps)
6. [Issues Fixed](#issues-fixed)
7. [API Reference](#api-reference)
8. [Testing](#testing)
9. [Example App](#example-app)

---

## Advantages

| Advantage | Description |
|-----------|-------------|
| **Backend-agnostic** | Swap Firebase, REST, GraphQL, Supabase, or a custom API without changing the core package |
| **Testable** | Use `FakeLocationStorageDataSource` — no emulator or network required |
| **Modular maps** | Google Maps and OpenStreetMap with feature flags; hide maps entirely when disabled |
| **Background tracking** | iOS survives force-quit via BGL; Android uses a sticky foreground service + alarm watchdog |
| **Automatic permissions** | Location, notifications, and battery optimization handled by `LocationTracking.start()` |
| **Reverse geocoding** | Addresses resolved on-device and attached to each location point |
| **Provider abstraction** | Map layer uses `TrackingMapProvider` — add new map vendors with minimal changes |
| **Optional Firebase adapter** | `nt_location_tracking_firebase` package for teams that want Firebase RTDB out of the box |
| **Clean separation** | Tracking, persistence, maps, and UI are independent modules |

---

## Package Structure

```
nt_location_tracking/                 # Core plugin (no backend SDK)
├── lib/
│   ├── nt_location_tracking.dart     # Public exports
│   └── src/
│       ├── location_tracking.dart    # Main facade API
│       ├── config/                   # Tracking configuration
│       ├── contracts/                # Backend interfaces (DI)
│       ├── exceptions/               # Backend-independent errors
│       ├── services/                 # Business logic (persistence)
│       ├── models/                   # LocationPoint, exceptions
│       ├── platform/                 # iOS / Android trackers
│       ├── geocoding/                # Address resolution
│       └── map/                      # Configurable map UI
├── android/                          # Foreground service + fused location
├── ios/                              # Native plugin shell (BGL used from Dart on iOS)
└── packages/
    └── nt_location_tracking_firebase/   # Optional Firebase RTDB adapter
```

---

## How Every Part Works

### 1. Public API — `LocationTracking`

The single entry point your app calls. It:

- Selects the correct platform tracker (iOS or Android)
- Subscribes to location updates and saves them via `LocationStorageDataSource`
- Requests permissions and battery exemption before starting

```
LocationTracking.initialize(config, dependencies)
        ↓
Platform tracker (iOS BGL / Android service)
        ↓
onLocation stream
        ↓
LocationPersistenceService → LocationStorageDataSource (your backend)
```

### 2. Contracts — `lib/src/contracts/`

| Interface | Purpose |
|-----------|---------|
| `LocationStorageDataSource` | **Write** locations to your backend |
| `LocationHistoryDataSource` | **Read** current location + history streams (optional, for UI) |
| `LocationTrackingDependencies` | Bundle passed to `initialize()` |

These interfaces have **no Firebase or HTTP imports** — only method signatures.

### 3. Configuration — `LocationTrackingConfig`

| Field | Purpose |
|-------|---------|
| `userId` | Opaque subject id (user, device, session) passed to storage |
| `distanceFilterMeters` | Minimum movement before a new point is recorded |
| `intervalSeconds` | Android location polling interval |
| `androidNotificationTitle/Text` | Foreground service notification content |
| `enableReverseGeocoding` | When `true`, reverse-geocode lat/lng and include `address` in API saves; when `false` (default), saves contain coordinates only |

### 4. Models — `LocationPoint`

Standard location payload: latitude, longitude, accuracy, timestamp, platform, address, speed, heading, isMoving. Serializes to `Map` for any backend.

### 5. Platform Layer

| Platform | Implementation | Why |
|----------|----------------|-----|
| **iOS** | `IosLocationTracker` + `flutter_background_geolocation` | Survives force-quit with `stopOnTerminate: false` |
| **Android** | `NativeLocationTracker` → `LocationTrackingService` | Sticky foreground service survives app swipe |

**Android native flow:**

```
LocationTrackingService (foreground)
    → FusedLocationProviderClient
    → AddressGeocoder (optional — when `enableReverseGeocoding` is true)
    → LocationEventDispatcher (EventChannel to Dart)
    → LocationStorageDataSource (when Flutter engine runs)
```

**Alarm watchdog** restarts the service if the OEM kills it.

### 6. Permissions — `LocationRuntimeRequirements`

Called automatically by `LocationTracking.start()`:

- **iOS:** Always location via BGL
- **Android:** Fine + background location + notifications + battery optimization exemption

### 7. Persistence — `LocationPersistenceService` + `LocationPersistencePolicy`

`LocationPersistenceService` writes to your backend. `LocationPersistencePolicy` throttles saves using `intervalSeconds` **or** `distanceFilterMeters` from config — the API is not called on every GPS tick. A periodic timer also flushes the latest location when the device is stationary.

### 8. Exceptions

| Exception | When |
|-----------|------|
| `LocationPermissionException` | User denied location permission |
| `AuthenticationException` | Backend auth failed (e.g. Firebase rules) |
| `NetworkException` | Connectivity or save failure |
| `TrackingException` | Base class for all tracking errors |

Adapters map backend-specific errors to these types.

### 9. Maps — `lib/src/map/`

| Component | Purpose |
|-----------|---------|
| `MapConfiguration` | Feature flags, API key, default provider |
| `TrackingMapProvider` | Abstract map contract |
| `GoogleMapsProvider` | Google Maps implementation |
| `OpenStreetMapProvider` | OSM tiles via `flutter_map` |
| `LocationTrackingMap` | Map widget with provider toggle |
| `LocationTracker` | Host-facing map widget |
| `AddressResolver` | Cached reverse geocoding for marker taps |
| `MarkerDetailsSheet` | Bottom sheet with address + coordinates |

### 10. Firebase Adapter — `packages/nt_location_tracking_firebase/`

| Class | Implements | Firebase path |
|-------|------------|---------------|
| `FirebaseLocationStorageDataSource` | `LocationStorageDataSource` | `/users/{id}/currentLocation` + `/locations/{pushId}` |
| `FirebaseLocationHistoryDataSource` | `LocationHistoryDataSource` | Real-time listeners on same paths |

Firebase stays **outside** the core plugin.

---

## How to Use

### Step 1 — Add dependencies

```yaml
dependencies:
  nt_location_tracking:
    path: ../nt_location_tracking
  nt_location_tracking_firebase:          # or your own adapter
    path: ../packages/nt_location_tracking_firebase
  firebase_core: ^3.13.0               # only if using Firebase adapter
```

### Step 2 — Platform setup

**Android** — add BGL maven repo in `android/build.gradle.kts`:

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("${project(":flutter_background_geolocation").projectDir}/libs")
        }
    }
}
```

**Android** — Google Maps API key in `AndroidManifest.xml` (if using maps):

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_KEY" />
```

**iOS** — add to `Info.plist`:

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Location is required in background.</string>
<key>UIBackgroundModes</key>
<array>
  <string>location</string>
</array>
```

### Step 3 — Initialize backend + tracking

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';
import 'package:nt_location_tracking_firebase/nt_location_tracking_firebase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required for iOS persistence when the app is force-quit
  LocationTracking.configureHeadlessBootstrap(() async {
    await Firebase.initializeApp();
    return LocationTrackingDependencies(
      storage: FirebaseLocationStorageDataSource(),
      history: FirebaseLocationHistoryDataSource(),
    );
  });
  await LocationTracking.registerHeadlessTask();

  await Firebase.initializeApp();

  await LocationTracking.initialize(
    config: LocationTrackingConfig(
      userId: 'user_123',
      androidNotificationTitle: 'Location Tracking',
      androidNotificationText: 'Tracking your location',
      distanceFilterMeters: 10,
      intervalSeconds: 20,
      enableReverseGeocoding: true, // set false to omit address from API saves
    ),
    dependencies: LocationTrackingDependencies(
      storage: FirebaseLocationStorageDataSource(),
      history: FirebaseLocationHistoryDataSource(),
    ),
  );

  // Permissions + battery exemption handled automatically
  await LocationTracking.start();

  LocationTracking.onLocation.listen((point) {
    print('${point.latitude}, ${point.longitude}');
  });
}
```

### Step 4 — Display a map (optional)

```dart
LocationTracker(
  googleMapsApiKey: 'YOUR_KEY',       // null = Google disabled
  enableGoogleMaps: true,
  enableOpenStreetMap: true,
  currentLocation: latestPoint,
  locations: historyPoints,
  height: 280,
)
```

### Step 5 — Custom backend (REST example)

```dart
class RestLocationStorageDataSource implements LocationStorageDataSource {
  RestLocationStorageDataSource(this.client);
  final http.Client client;

  @override
  Future<void> saveLocation(
    LocationPoint point, {
    required String subjectId,
  }) async {
    final response = await client.post(
      Uri.parse('https://api.example.com/users/$subjectId/locations'),
      body: jsonEncode(point.toMap()),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 401) {
      throw AuthenticationException('Unauthorized');
    }
    if (response.statusCode >= 400) {
      throw NetworkException('Save failed: ${response.statusCode}');
    }
  }
}
```

---

## Maps

| Google | OSM | Result |
|--------|-----|--------|
| ✅ | ✅ | Provider switcher shown |
| ✅ | ❌ | Google only |
| ❌ | ✅ | OpenStreetMap only |
| ❌ | ❌ | Map hidden |

Marker taps show address, latitude, and longitude in a bottom sheet.

---

## Issues Fixed

| Issue | Root cause | Fix |
|-------|-----------|-----|
| Android tracking stops ~2 min after swipe | WorkManager alone killed by OEM | Dedicated `LocationTrackingService` with `START_STICKY` + alarm watchdog |
| Android release crash (`WorkDatabase_Impl`) | ProGuard stripped WorkManager classes | `proguard-rules.pro` + `consumer-rules.pro` |
| Android `FusedLocationProviderClient` crash | Play Services version mismatch | Pinned `play-services-location:20.0.0` |
| Android crash on location thread | Firebase/EventChannel called off main thread | `LocationEventDispatcher` posts to main thread |
| iOS SPM / CocoaPods conflicts | Binary target identity errors | SPM disabled; CocoaPods with static frameworks |
| iOS build errors after pod conflicts | Stale `Podfile.lock` | Clean pod install workflow documented |
| Google Maps crash without API key | Missing native manifest key | Manifest placeholder + graceful OSM fallback |
| Layout overflow on home screen | Fixed `Column` too tall | `SingleChildScrollView` |
| Firebase hardcoded in plugin | Tight coupling | Backend-agnostic contracts + adapter package |
| Manual permission buttons in example | UX friction | Auto-request in `LocationTracking.start()` |
| Duplicate Firebase writes (iOS) | Native + Dart both writing | Single write path via Dart `LocationStorageDataSource` |
| `NetworkOnMainThreadException` after swipe (release) | Terminated HTTP save on main thread | Background executor in `LocationEventDispatcher` |

---

## API Reference

| Method | Description |
|--------|-------------|
| `initialize(config, dependencies)` | Configure tracking + inject backend |
| `start()` | Request permissions, battery exemption, begin tracking |
| `stop()` | Flush latest location to backend, then stop tracking |
| `isTracking()` | Whether tracking is active |
| `onLocation` | Stream of updates (while Flutter engine runs) |
| `registerHeadlessTask()` | Register iOS headless persistence (call from `main()`) |
| `configureHeadlessBootstrap(...)` | Rebuild dependencies in headless isolate |
| `refreshTerminatedPersistence()` | Re-sync HTTP/Firebase config + auth to native after login |
| `onPersistenceError` | Stream of backend save failures; tracking continues |
| `getCurrentLocation()` | Latest known location |
| `dependencies` | Access injected backend adapters |
| `requestPermissions()` | Manual permission request |
| `ensureBatteryOptimizationExemption()` | Manual battery exemption (Android) |
| `openBatteryOptimizationSettings()` | Open battery settings (Android fallback) |

---

## Testing

```bash
fvm flutter test
```

Uses `FakeLocationStorageDataSource` — no Firebase emulator needed.

**Manual checklist:**

1. Foreground tracking → locations appear in backend
2. Background → updates continue
3. iOS force-quit → tracking resumes after movement
4. Android swipe away → foreground notification persists
5. Denied permissions → app does not crash
6. Map markers → tap shows address + coordinates
7. **Terminated app** → Android FGS + iOS BGL headless still save to backend (Firebase adapter)

---

## Terminated-app persistence

When the user swipes the app away or force-quits:

| Platform | Tracking | API saves |
|----------|----------|-----------|
| **Android** | Foreground service continues | Native writer uses your adapter config (`firebase` or `http`) |
| **iOS** | BGL continues (`stopOnTerminate: false`) | BGL headless task rebuilds your `LocationStorageDataSource` |

Your storage adapter must implement [LocationTerminatedPersistenceProvider] for terminated saves:

- **Firebase** — `FirebaseLocationStorageDataSource` (built-in)
- **REST** — use [HttpTerminatedPersistenceConfig] with `authToken` and optional `collectorId`

After login, call `LocationTracking.refreshTerminatedPersistence()` so Android native prefs receive the Bearer token before the app is swiped away.

Throttle rules (`intervalSeconds` / `distanceFilterMeters`) apply in terminated mode too.

Debug Android terminated saves: `adb logcat -s NtLocationTracking`

---

## Example App

```bash
cd example
flutterfire configure    # generates firebase_options.dart
fvm flutter run
```

See `example/lib/config/backend_config.dart` for Firebase adapter wiring.

---

## License

See [LICENSE](LICENSE).
