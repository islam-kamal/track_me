package com.example.nt_location_tracking

import android.content.Context
import android.content.SharedPreferences

class TrackingPreferences(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var isTracking: Boolean
        get() = prefs.getBoolean(KEY_IS_TRACKING, false)
        set(value) = prefs.edit().putBoolean(KEY_IS_TRACKING, value).apply()

    var userId: String?
        get() = prefs.getString(KEY_USER_ID, null)
        set(value) = prefs.edit().putString(KEY_USER_ID, value).apply()

    var distanceFilterMeters: Float
        get() = prefs.getFloat(KEY_DISTANCE_FILTER, DEFAULT_DISTANCE_FILTER)
        set(value) = prefs.edit().putFloat(KEY_DISTANCE_FILTER, value).apply()

    var intervalSeconds: Int
        get() = prefs.getInt(KEY_INTERVAL_SECONDS, DEFAULT_INTERVAL_SECONDS)
        set(value) = prefs.edit().putInt(KEY_INTERVAL_SECONDS, value).apply()

    var enableReverseGeocoding: Boolean
        get() = prefs.getBoolean(KEY_ENABLE_REVERSE_GEOCODING, false)
        set(value) = prefs.edit().putBoolean(KEY_ENABLE_REVERSE_GEOCODING, value).apply()

    var notificationTitle: String
        get() = prefs.getString(KEY_NOTIFICATION_TITLE, DEFAULT_NOTIFICATION_TITLE)
            ?: DEFAULT_NOTIFICATION_TITLE
        set(value) = prefs.edit().putString(KEY_NOTIFICATION_TITLE, value).apply()

    var notificationText: String
        get() = prefs.getString(KEY_NOTIFICATION_TEXT, DEFAULT_NOTIFICATION_TEXT)
            ?: DEFAULT_NOTIFICATION_TEXT
        set(value) = prefs.edit().putString(KEY_NOTIFICATION_TEXT, value).apply()

    var terminatedPersistenceAdapter: String?
        get() = prefs.getString(KEY_TERMINATED_ADAPTER, null)
        set(value) = prefs.edit().putString(KEY_TERMINATED_ADAPTER, value).apply()

    var firebaseDatabaseUrl: String?
        get() = prefs.getString(KEY_FIREBASE_DATABASE_URL, null)
        set(value) = prefs.edit().putString(KEY_FIREBASE_DATABASE_URL, value).apply()

    var httpEndpointTemplate: String?
        get() = prefs.getString(KEY_HTTP_ENDPOINT, null)
        set(value) = prefs.edit().putString(KEY_HTTP_ENDPOINT, value).apply()

    var httpHeaders: String?
        get() = prefs.getString(KEY_HTTP_HEADERS, null)
        set(value) = prefs.edit().putString(KEY_HTTP_HEADERS, value).apply()

    var collectorId: String?
        get() = prefs.getString(KEY_COLLECTOR_ID, null)
        set(value) = prefs.edit().putString(KEY_COLLECTOR_ID, value).apply()

    var lastPersistedLatitude: Double?
        get() = prefs.getString(KEY_LAST_PERSISTED_LAT, null)?.toDoubleOrNull()
        set(value) = prefs.edit().putString(KEY_LAST_PERSISTED_LAT, value?.toString()).apply()

    var lastPersistedLongitude: Double?
        get() = prefs.getString(KEY_LAST_PERSISTED_LNG, null)?.toDoubleOrNull()
        set(value) = prefs.edit().putString(KEY_LAST_PERSISTED_LNG, value?.toString()).apply()

    var lastPersistedAtMs: Long
        get() = prefs.getLong(KEY_LAST_PERSISTED_AT_MS, 0L)
        set(value) = prefs.edit().putLong(KEY_LAST_PERSISTED_AT_MS, value).apply()

    fun saveTerminatedPersistenceConfig(
        adapter: String?,
        firebaseDatabaseUrl: String?,
        httpEndpointTemplate: String?,
        httpHeaders: String?,
        collectorId: String?,
    ) {
        prefs.edit()
            .putString(KEY_TERMINATED_ADAPTER, adapter)
            .putString(KEY_FIREBASE_DATABASE_URL, firebaseDatabaseUrl)
            .putString(KEY_HTTP_ENDPOINT, httpEndpointTemplate)
            .putString(KEY_HTTP_HEADERS, httpHeaders)
            .putString(KEY_COLLECTOR_ID, collectorId)
            .apply()
    }

    fun savePersistenceState(latitude: Double, longitude: Double, timestampMs: Long) {
        prefs.edit()
            .putString(KEY_LAST_PERSISTED_LAT, latitude.toString())
            .putString(KEY_LAST_PERSISTED_LNG, longitude.toString())
            .putLong(KEY_LAST_PERSISTED_AT_MS, timestampMs)
            .apply()
    }

    fun saveConfig(
        userId: String,
        distanceFilterMeters: Float,
        intervalSeconds: Int,
        notificationTitle: String,
        notificationText: String,
        enableReverseGeocoding: Boolean = false,
    ) {
        prefs.edit()
            .putString(KEY_USER_ID, userId)
            .putFloat(KEY_DISTANCE_FILTER, distanceFilterMeters)
            .putInt(KEY_INTERVAL_SECONDS, intervalSeconds)
            .putString(KEY_NOTIFICATION_TITLE, notificationTitle)
            .putString(KEY_NOTIFICATION_TEXT, notificationText)
            .putBoolean(KEY_ENABLE_REVERSE_GEOCODING, enableReverseGeocoding)
            .apply()
    }

    companion object {
        private const val PREFS_NAME = "location_tracking_prefs"
        private const val KEY_IS_TRACKING = "is_tracking"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_DISTANCE_FILTER = "distance_filter"
        private const val KEY_INTERVAL_SECONDS = "interval_seconds"
        private const val KEY_ENABLE_REVERSE_GEOCODING = "enable_reverse_geocoding"
        private const val KEY_NOTIFICATION_TITLE = "notification_title"
        private const val KEY_NOTIFICATION_TEXT = "notification_text"
        private const val KEY_TERMINATED_ADAPTER = "terminated_adapter"
        private const val KEY_FIREBASE_DATABASE_URL = "firebase_database_url"
        private const val KEY_HTTP_ENDPOINT = "http_endpoint_template"
        private const val KEY_HTTP_HEADERS = "http_headers"
        private const val KEY_COLLECTOR_ID = "collector_id"
        private const val KEY_LAST_PERSISTED_LAT = "last_persisted_lat"
        private const val KEY_LAST_PERSISTED_LNG = "last_persisted_lng"
        private const val KEY_LAST_PERSISTED_AT_MS = "last_persisted_at_ms"

        const val DEFAULT_DISTANCE_FILTER = 10f
        const val DEFAULT_INTERVAL_SECONDS = 30
        const val DEFAULT_NOTIFICATION_TITLE = "Location Tracking"
        const val DEFAULT_NOTIFICATION_TEXT = "Tracking your location in the background"
    }
}
