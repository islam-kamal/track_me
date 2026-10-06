package com.example.nt_location_tracking.service

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.os.Build
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.example.nt_location_tracking.LocationEventDispatcher
import com.example.nt_location_tracking.LocationWorkScheduler
import com.example.nt_location_tracking.R
import com.example.nt_location_tracking.TrackingAlarmScheduler
import com.example.nt_location_tracking.TrackingPreferences
import com.example.nt_location_tracking.geocoding.AddressGeocoder
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Dedicated foreground service for continuous location tracking.
 *
 * Design decisions:
 * - [START_STICKY] + alarm watchdog: survive app swipe from recents
 * - Separate HandlerThread: avoid blocking the main thread with GPS callbacks
 * - No direct backend writes: locations go to Dart via [LocationEventDispatcher]
 *   so the host app controls storage through [LocationStorageDataSource]
 */
class LocationTrackingService : Service() {

    private var locationCallback: LocationCallback? = null
    private var locationLooper: Looper? = null
    private var locationThread: HandlerThread? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        running.set(true)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val prefs = TrackingPreferences(applicationContext)
        if (!prefs.isTracking || prefs.userId.isNullOrBlank()) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (!hasRequiredPermissions()) {
            stopSelf()
            return START_NOT_STICKY
        }

        startForegroundWithNotification(prefs)
        startLocationUpdates(prefs)
        LocationWorkScheduler.scheduleWatchdog(applicationContext)
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        val prefs = TrackingPreferences(applicationContext)
        if (prefs.isTracking) {
            TrackingAlarmScheduler.scheduleImmediateRestart(applicationContext)
        }
    }

    override fun onDestroy() {
        stopLocationUpdates()
        running.set(false)
        val prefs = TrackingPreferences(applicationContext)
        if (prefs.isTracking) {
            TrackingAlarmScheduler.scheduleImmediateRestart(applicationContext)
        }
        super.onDestroy()
    }

    private fun startLocationUpdates(prefs: TrackingPreferences) {
        stopLocationUpdates()

        val userId = prefs.userId ?: return
        val intervalMs = prefs.intervalSeconds * 1000L
        val fusedClient = LocationServices.getFusedLocationProviderClient(this)

        val thread = HandlerThread("LocationTrackingThread").apply { start() }
        locationThread = thread
        locationLooper = thread.looper

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
        locationCallback = callback

        val request = LocationRequest.create()
            .setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY)
            .setInterval(intervalMs)
            .setFastestInterval(intervalMs)
            .setSmallestDisplacement(prefs.distanceFilterMeters)
            .setWaitForAccurateLocation(false)

        fusedClient.requestLocationUpdates(
            request,
            callback,
            locationLooper!!,
        )
    }

    private fun stopLocationUpdates() {
        val callback = locationCallback
        if (callback != null) {
            LocationServices.getFusedLocationProviderClient(this)
                .removeLocationUpdates(callback)
        }
        locationCallback = null
        locationLooper = null
        locationThread?.quitSafely()
        locationThread = null
    }

    private fun startForegroundWithNotification(prefs: TrackingPreferences) {
        createNotificationChannel()
        val notification = buildNotification(prefs)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun hasRequiredPermissions(): Boolean {
        val fineGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val coarseGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        if (!fineGranted && !coarseGranted) {
            return false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Location Tracking",
            NotificationManager.IMPORTANCE_LOW,
        )
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(prefs: TrackingPreferences): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(prefs.notificationTitle)
            .setContentText(prefs.notificationText)
            .setSmallIcon(R.drawable.ic_location_tracking)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "location_tracking_channel"
        private const val NOTIFICATION_ID = 1001

        private val running = AtomicBoolean(false)

        val isRunning: Boolean
            get() = running.get()

        fun start(context: Context) {
            val intent = Intent(context, LocationTrackingService::class.java)
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, LocationTrackingService::class.java))
        }
    }
}
