package com.example.nt_location_tracking.terminated

import android.content.Context
import android.location.Location
import android.util.Log
import com.example.nt_location_tracking.TrackingPreferences
import com.example.nt_location_tracking.toIso8601String
import com.example.nt_location_tracking.toPayload
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Persists locations from the foreground service when the Flutter engine is
 * not running (app terminated / swiped away).
 */
object TerminatedLocationPersister {
    private const val TAG = "NtLocationTracking"

    fun persistIfNeeded(
        context: Context,
        location: Location,
        address: String?,
        isMoving: Boolean = true,
    ) {
        val prefs = TrackingPreferences(context)
        val userId = prefs.userId
        if (userId.isNullOrBlank()) {
            Log.w(TAG, "Terminated save skipped: missing user id")
            return
        }

        val adapter = prefs.terminatedPersistenceAdapter
        if (adapter.isNullOrBlank()) {
            Log.w(TAG, "Terminated save skipped: missing adapter config")
            return
        }

        if (!prefs.isTracking) {
            Log.w(TAG, "Terminated save skipped: tracking is not active")
            return
        }

        if (!shouldPersist(prefs, location)) {
            return
        }

        val payload = buildPayload(
            location,
            prefs,
            isMoving,
            if (prefs.enableReverseGeocoding) address else null,
        )
        val success = when (adapter) {
            "firebase" -> writeFirebase(
                context = context,
                userId = userId,
                payload = payload,
                databaseUrl = prefs.firebaseDatabaseUrl,
            )
            "http" -> HttpTerminatedWriter.write(
                userId = userId,
                payload = payload,
                endpointTemplate = prefs.httpEndpointTemplate,
                headersRaw = prefs.httpHeaders,
            )
            else -> {
                Log.w(TAG, "Terminated save skipped: unknown adapter '$adapter'")
                false
            }
        }

        if (success) {
            prefs.savePersistenceState(
                latitude = location.latitude,
                longitude = location.longitude,
                timestampMs = System.currentTimeMillis(),
            )
        }
    }

    private fun buildPayload(
        location: Location,
        prefs: TrackingPreferences,
        isMoving: Boolean,
        address: String?,
    ): Map<String, Any?> {
        val payload = location.toPayload(isMoving, address).toMutableMap()
        // Match Dart LocationPoint.toMap() — UTC timestamp at save time.
        payload["timestamp"] = System.currentTimeMillis().toIso8601String()
        val collectorId = prefs.collectorId
        if (!collectorId.isNullOrBlank()) {
            payload["collectorId"] = collectorId
        }
        return payload
    }

    private fun writeFirebase(
        context: Context,
        userId: String,
        payload: Map<String, Any?>,
        databaseUrl: String?,
    ): Boolean {
        return try {
            FirebaseTerminatedWriter.write(
                context = context,
                userId = userId,
                payload = payload,
                databaseUrl = databaseUrl,
            )
            Log.i(TAG, "Terminated Firebase save succeeded")
            true
        } catch (error: Exception) {
            Log.w(TAG, "Terminated Firebase save failed: ${error.message}")
            false
        }
    }

    private fun shouldPersist(prefs: TrackingPreferences, location: Location): Boolean {
        val lastLat = prefs.lastPersistedLatitude
        val lastLng = prefs.lastPersistedLongitude
        val lastAt = prefs.lastPersistedAtMs
        if (lastLat == null || lastLng == null || lastAt == 0L) {
            return true
        }

        val elapsedSeconds = (System.currentTimeMillis() - lastAt) / 1000
        if (elapsedSeconds >= prefs.intervalSeconds) {
            return true
        }

        val distance = distanceMeters(lastLat, lastLng, location.latitude, location.longitude)
        return distance >= prefs.distanceFilterMeters
    }

    private fun distanceMeters(
        lat1: Double,
        lng1: Double,
        lat2: Double,
        lng2: Double,
    ): Double {
        val earthRadius = 6371000.0
        val dLat = Math.toRadians(lat2 - lat1)
        val dLng = Math.toRadians(lng2 - lng1)
        val a = sin(dLat / 2) * sin(dLat / 2) +
            cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
            sin(dLng / 2) * sin(dLng / 2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }
}
