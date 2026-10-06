package com.example.nt_location_tracking

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import com.example.nt_location_tracking.receiver.TrackingAlarmReceiver

internal object TrackingAlarmScheduler {
    private const val WATCHDOG_REQUEST_CODE = 9101
    private const val WATCHDOG_INTERVAL_MS = 60_000L

    fun scheduleWatchdog(context: Context) {
        val appContext = context.applicationContext
        val alarmManager = appContext.getSystemService(AlarmManager::class.java) ?: return
        val pendingIntent = pendingWatchdogIntent(appContext)
        val triggerAt = SystemClock.elapsedRealtime() + WATCHDOG_INTERVAL_MS
        alarmManager.setInexactRepeating(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            triggerAt,
            WATCHDOG_INTERVAL_MS,
            pendingIntent,
        )
    }

    fun cancelWatchdog(context: Context) {
        val appContext = context.applicationContext
        val alarmManager = appContext.getSystemService(AlarmManager::class.java) ?: return
        alarmManager.cancel(pendingWatchdogIntent(appContext))
    }

    fun scheduleImmediateRestart(context: Context) {
        val appContext = context.applicationContext
        val alarmManager = appContext.getSystemService(AlarmManager::class.java) ?: return
        val intent = Intent(appContext, TrackingAlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            appContext,
            WATCHDOG_REQUEST_CODE + 1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.set(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + 1_000L,
            pendingIntent,
        )
    }

    private fun pendingWatchdogIntent(context: Context): PendingIntent {
        val intent = Intent(context, TrackingAlarmReceiver::class.java)
        return PendingIntent.getBroadcast(
            context,
            WATCHDOG_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
