package com.example.nt_location_tracking.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.example.nt_location_tracking.LocationWorkScheduler
import com.example.nt_location_tracking.TrackingPreferences

class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED) {
            return
        }
        val prefs = TrackingPreferences(context.applicationContext)
        if (prefs.isTracking) {
            LocationWorkScheduler.enqueue(context.applicationContext)
        }
    }
}
