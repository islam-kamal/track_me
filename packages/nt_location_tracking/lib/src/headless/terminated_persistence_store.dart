import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_point.dart';
import '../services/location_persistence_policy.dart';
import 'location_tracking_headless.dart';

/// Persists tracking config and throttle state for headless/native saves.
class TerminatedPersistenceStore {
  static const _keyUserId = 'nt_lt_user_id';
  static const _keyInterval = 'nt_lt_interval_seconds';
  static const _keyDistance = 'nt_lt_distance_filter';
  static const _keyIsTracking = 'nt_lt_is_tracking';
  static const _keyEnableGeocoding = 'nt_lt_enable_reverse_geocoding';
  static const _keyAdapter = 'nt_lt_terminated_adapter';
  static const _keyFirebaseUrl = 'nt_lt_firebase_database_url';
  static const _keyHttpEndpoint = 'nt_lt_http_endpoint';
  static const _keyHttpHeaders = 'nt_lt_http_headers';
  static const _keyLastLat = 'nt_lt_last_persisted_lat';
  static const _keyLastLng = 'nt_lt_last_persisted_lng';
  static const _keyLastPersistedAt = 'nt_lt_last_persisted_at_ms';

  Future<void> saveTrackingConfig({
    required String userId,
    required int intervalSeconds,
    required double distanceFilterMeters,
    required bool isTracking,
    bool enableReverseGeocoding = false,
    Map<String, dynamic>? terminatedPersistence,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setInt(_keyInterval, intervalSeconds);
    await prefs.setDouble(_keyDistance, distanceFilterMeters);
    await prefs.setBool(_keyIsTracking, isTracking);
    await prefs.setBool(_keyEnableGeocoding, enableReverseGeocoding);

    if (terminatedPersistence == null) {
      await prefs.remove(_keyAdapter);
      await prefs.remove(_keyFirebaseUrl);
      await prefs.remove(_keyHttpEndpoint);
      await prefs.remove(_keyHttpHeaders);
      return;
    }

    final adapter = terminatedPersistence['adapter'] as String?;
    await prefs.setString(_keyAdapter, adapter ?? '');

    await prefs.setString(
      _keyFirebaseUrl,
      terminatedPersistence['databaseUrl'] as String? ?? '',
    );
    await prefs.setString(
      _keyHttpEndpoint,
      terminatedPersistence['endpointTemplate'] as String? ?? '',
    );
    final headers = terminatedPersistence['headers'];
    if (headers is Map) {
      await prefs.setString(
        _keyHttpHeaders,
        headers.entries.map((e) => '${e.key}:${e.value}').join('\n'),
      );
    } else {
      await prefs.remove(_keyHttpHeaders);
    }
  }

  Future<TerminatedTrackingConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return TerminatedTrackingConfig(
      userId: userId,
      intervalSeconds: prefs.getInt(_keyInterval) ?? 30,
      distanceFilterMeters: prefs.getDouble(_keyDistance) ?? 10,
      isTracking: prefs.getBool(_keyIsTracking) ?? false,
      enableReverseGeocoding: prefs.getBool(_keyEnableGeocoding) ?? false,
    );
  }

  Future<void> savePolicyState(LocationPersistencePolicy policy) async {
    final prefs = await SharedPreferences.getInstance();
    final last = policy.lastPersistedPoint;
    final at = policy.lastPersistedAt;
    if (last != null) {
      await prefs.setDouble(_keyLastLat, last.latitude);
      await prefs.setDouble(_keyLastLng, last.longitude);
    }
    if (at != null) {
      await prefs.setInt(_keyLastPersistedAt, at.millisecondsSinceEpoch);
    }
  }

  Future<void> applyPolicyState(LocationPersistencePolicy policy) async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_keyLastLat);
    final lng = prefs.getDouble(_keyLastLng);
    final atMs = prefs.getInt(_keyLastPersistedAt);
    if (lat == null || lng == null || atMs == null) {
      return;
    }

    policy.markPersisted(
      LocationPoint(
        latitude: lat,
        longitude: lng,
        accuracy: 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(atMs),
        platform: 'restored',
      ),
      at: DateTime.fromMillisecondsSinceEpoch(atMs),
    );
  }
}
