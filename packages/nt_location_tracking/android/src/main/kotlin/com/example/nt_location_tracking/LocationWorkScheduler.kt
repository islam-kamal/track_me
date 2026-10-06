package com.example.nt_location_tracking

import android.content.Context
import androidx.work.WorkManager
import com.example.nt_location_tracking.service.LocationTrackingService

object LocationWorkScheduler {
    private const val LEGACY_WORK_NAME = "location_tracking_work"

    /**
     * Starts the location foreground service and a periodic alarm watchdog that
     * restarts tracking if Samsung/OEM kills the service after the app is swiped away.
     */
    fun enqueue(context: Context) {
        val appContext = context.applicationContext
        // Cancel legacy WorkManager worker from older plugin versions.
        WorkManager.getInstance(appContext).cancelUniqueWork(LEGACY_WORK_NAME)
        LocationTrackingService.start(appContext)
        scheduleWatchdog(appContext)
    }

    fun cancel(context: Context) {
        val appContext = context.applicationContext
        WorkManager.getInstance(appContext).cancelUniqueWork(LEGACY_WORK_NAME)
        cancelWatchdog(appContext)
        LocationTrackingService.stop(appContext)
    }

    fun scheduleWatchdog(context: Context) {
        TrackingAlarmScheduler.scheduleWatchdog(context.applicationContext)
    }

    fun cancelWatchdog(context: Context) {
        TrackingAlarmScheduler.cancelWatchdog(context.applicationContext)
    }
}
