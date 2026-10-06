package com.example.nt_location_tracking.worker

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.os.Build
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.work.CoroutineWorker
import androidx.work.ForegroundInfo
import androidx.work.WorkerParameters
import com.example.nt_location_tracking.LocationEventDispatcher
import com.example.nt_location_tracking.R
import com.example.nt_location_tracking.TrackingPreferences
import com.example.nt_location_tracking.geocoding.AddressGeocoder
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.suspendCancellableCoroutine

class LocationWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val prefs = TrackingPreferences(applicationContext)
        val userId = prefs.userId
        if (userId.isNullOrBlank()) {
            return Result.failure()
        }
        if (!hasLocationPermissions()) {
            return Result.failure()
        }

        return try {
            setForeground(createForegroundInfo(prefs))
            trackLocations(prefs, userId)
            Result.success()
        } catch (_: SecurityException) {
            Result.failure()
        } catch (e: CancellationException) {
            throw e
        } catch (_: Exception) {
            Result.retry()
        }
    }

    private suspend fun trackLocations(prefs: TrackingPreferences, userId: String) {
        val fusedClient = LocationServices.getFusedLocationProviderClient(applicationContext)
        val intervalMs = prefs.intervalSeconds * 1000L

        suspendCancellableCoroutine<Unit> { continuation ->
            val callback = object : LocationCallback() {
                override fun onLocationResult(result: LocationResult) {
                    val location: Location = result.lastLocation ?: return
                    val address = if (prefs.enableReverseGeocoding) {
                        AddressGeocoder.reverseGeocode(
                            applicationContext,
                            location.latitude,
                            location.longitude,
                        )
                    } else {
                        null
                    }
                    LocationEventDispatcher.dispatch(
                        applicationContext,
                        location,
                        address = address,
                    )
                }
            }

            val request = LocationRequest.create()
                .setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY)
                .setInterval(intervalMs)
                .setFastestInterval(intervalMs)
                .setSmallestDisplacement(prefs.distanceFilterMeters)
                .setWaitForAccurateLocation(false)

            fusedClient.requestLocationUpdates(
                request,
                callback,
                Looper.getMainLooper(),
            )

            continuation.invokeOnCancellation {
                fusedClient.removeLocationUpdates(callback)
            }
        }
    }

    private fun hasLocationPermissions(): Boolean {
        val fineGranted = ContextCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val coarseGranted = ContextCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        if (!fineGranted && !coarseGranted) {
            return false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return ContextCompat.checkSelfPermission(
                applicationContext,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    private fun createForegroundInfo(prefs: TrackingPreferences): ForegroundInfo {
        createNotificationChannel()
        val notification = buildNotification(prefs)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ForegroundInfo(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION,
            )
        } else {
            ForegroundInfo(NOTIFICATION_ID, notification)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val manager = applicationContext.getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Location Tracking",
            NotificationManager.IMPORTANCE_LOW,
        )
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(prefs: TrackingPreferences): Notification {
        return NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setContentTitle(prefs.notificationTitle)
            .setContentText(prefs.notificationText)
            .setSmallIcon(R.drawable.ic_location_tracking)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "location_tracking_channel"
        private const val NOTIFICATION_ID = 1001
    }
}
