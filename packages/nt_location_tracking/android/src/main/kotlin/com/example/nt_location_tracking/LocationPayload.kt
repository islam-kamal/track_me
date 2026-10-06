package com.example.nt_location_tracking

import android.location.Location
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

internal fun Location.toPayload(isMoving: Boolean, address: String? = null): Map<String, Any?> {
    return buildMap {
        put("latitude", latitude)
        put("longitude", longitude)
        put("accuracy", accuracy.toDouble())
        put("altitude", altitude)
        put("speed", speed.toDouble())
        put("heading", bearing.toDouble())
        put("timestamp", time.toIso8601String())
        put("platform", "android")
        put("isMoving", isMoving)
        if (!address.isNullOrBlank()) {
            put("address", address)
        }
    }
}

internal fun Long.toIso8601String(): String {
    val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
    formatter.timeZone = TimeZone.getTimeZone("UTC")
    return formatter.format(this)
}
