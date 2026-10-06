package com.example.nt_location_tracking.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.example.nt_location_tracking.LocationWorkScheduler
import com.example.nt_location_tracking.TrackingPreferences
import com.example.nt_location_tracking.service.LocationTrackingService

/**
 * Restarts location tracking when the OS stops the foreground service.
 *
 * Triggered by AlarmManager while [TrackingPreferences.isTracking] is true.
 */
class TrackingAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val prefs = TrackingPreferences(context.applicationContext)
        if (!prefs.isTracking || prefs.userId.isNullOrBlank()) {
            LocationWorkScheduler.cancelWatchdog(context.applicationContext)
            return
        }
        if (!LocationTrackingService.isRunning) {
            LocationTrackingService.start(context.applicationContext)
        }
        LocationWorkScheduler.scheduleWatchdog(context.applicationContext)
    }
}
