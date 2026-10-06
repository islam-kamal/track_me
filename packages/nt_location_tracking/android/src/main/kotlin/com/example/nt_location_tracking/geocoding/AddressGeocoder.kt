package com.example.nt_location_tracking.geocoding

import android.content.Context
import android.location.Geocoder
import android.os.Build
import java.util.Locale
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

internal object AddressGeocoder {
    fun reverseGeocode(
        context: Context,
        latitude: Double,
        longitude: Double,
    ): String? {
        if (!Geocoder.isPresent()) {
            return null
        }

        return try {
            val geocoder = Geocoder(context.applicationContext, Locale.getDefault())
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                reverseGeocodeAsync(geocoder, latitude, longitude)
            } else {
                @Suppress("DEPRECATION")
                geocoder.getFromLocation(latitude, longitude, 1)
                    ?.firstOrNull()
                    ?.getAddressLine(0)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun reverseGeocodeAsync(
        geocoder: Geocoder,
        latitude: Double,
        longitude: Double,
    ): String? {
        val latch = CountDownLatch(1)
        var address: String? = null

        geocoder.getFromLocation(latitude, longitude, 1) { addresses ->
            address = addresses.firstOrNull()?.getAddressLine(0)
            latch.countDown()
        }

        latch.await(5, TimeUnit.SECONDS)
        return address
    }
}
