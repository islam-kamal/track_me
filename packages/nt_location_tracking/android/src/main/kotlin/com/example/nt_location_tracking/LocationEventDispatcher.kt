package com.example.nt_location_tracking

import android.content.Context
import android.location.Location
import android.os.Handler
import android.os.Looper
import com.example.nt_location_tracking.terminated.TerminatedLocationPersister
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicReference

/**
 * Bridges native Android location updates to the Flutter EventChannel.
 *
 * When the Flutter engine is not running, locations are persisted natively
 * via [TerminatedLocationPersister] using the adapter config from [initialize].
 */
object LocationEventDispatcher {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val persistenceExecutor = Executors.newSingleThreadExecutor()
    private val eventSink = AtomicReference<((Map<String, Any?>) -> Unit)?>(null)
    private val latestLocation = AtomicReference<Location?>(null)

    fun setEventSink(sink: ((Map<String, Any?>) -> Unit)?) {
        eventSink.set(sink)
    }

    fun hasEventSink(): Boolean = eventSink.get() != null

    fun dispatch(
        context: Context,
        location: Location,
        isMoving: Boolean = true,
        address: String? = null,
    ) {
        latestLocation.set(location)
        val payload = location.toPayload(isMoving, address)
        val appContext = context.applicationContext
        val sink = eventSink.get()
        if (sink != null) {
            mainHandler.post {
                try {
                    sink.invoke(payload)
                } catch (_: Exception) {
                    // Engine dead but sink not cleared — fall back to native save.
                    runTerminatedPersist(appContext, location, address, isMoving)
                }
            }
            return
        }

        runTerminatedPersist(appContext, location, address, isMoving)
    }

    private fun runTerminatedPersist(
        context: Context,
        location: Location,
        address: String?,
        isMoving: Boolean,
    ) {
        persistenceExecutor.execute {
            try {
                TerminatedLocationPersister.persistIfNeeded(
                    context,
                    location,
                    address,
                    isMoving,
                )
            } catch (_: Exception) {
                // Keep the foreground service alive when a terminated save fails.
            }
        }
    }

    fun getLatestLocation(): Location? = latestLocation.get()
}
