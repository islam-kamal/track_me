package com.example.nt_location_tracking

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class LocationTrackingPlugin :
    FlutterPlugin,
    MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var applicationContext: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "nt_location_tracking")
        eventChannel = EventChannel(binding.binaryMessenger, "nt_location_tracking/events")
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("invalid_args", "Config map is required", null)
                    return
                }
                initialize(args)
                result.success(null)
            }

            "startTracking" -> {
                val prefs = TrackingPreferences(applicationContext)
                prefs.isTracking = true
                LocationWorkScheduler.enqueue(applicationContext)
                result.success(null)
            }

            "stopTracking" -> {
                val prefs = TrackingPreferences(applicationContext)
                prefs.isTracking = false
                LocationWorkScheduler.cancel(applicationContext)
                result.success(null)
            }

            "isTracking" -> {
                val prefs = TrackingPreferences(applicationContext)
                result.success(prefs.isTracking)
            }

            "getCurrentLocation" -> {
                val location: Location? = LocationEventDispatcher.getLatestLocation()
                if (location == null) {
                    result.success(null)
                } else {
                    result.success(location.toPayload(isMoving = true))
                }
            }

            "openBatteryOptimizationSettings" -> {
                result.success(openBatteryOptimizationSettings())
            }

            "requestPermissions" -> {
                result.success(hasLocationPermissions())
            }

            "configureTerminatedPersistence" -> {
                val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                configureTerminatedPersistence(args)
                result.success(null)
            }

            "syncPersistenceState" -> {
                val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                syncPersistenceState(args)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun initialize(args: Map<*, *>) {
        val userId = args["userId"] as? String ?: return
        val distanceFilter = (args["distanceFilterMeters"] as? Number)?.toFloat()
            ?: TrackingPreferences.DEFAULT_DISTANCE_FILTER
        val intervalSeconds = (args["intervalSeconds"] as? Number)?.toInt()
            ?: TrackingPreferences.DEFAULT_INTERVAL_SECONDS
        val notificationTitle = args["androidNotificationTitle"] as? String
            ?: TrackingPreferences.DEFAULT_NOTIFICATION_TITLE
        val notificationText = args["androidNotificationText"] as? String
            ?: TrackingPreferences.DEFAULT_NOTIFICATION_TEXT
        val enableReverseGeocoding = args["enableReverseGeocoding"] as? Boolean ?: false

        TrackingPreferences(applicationContext).saveConfig(
            userId = userId,
            distanceFilterMeters = distanceFilter,
            intervalSeconds = intervalSeconds,
            notificationTitle = notificationTitle,
            notificationText = notificationText,
            enableReverseGeocoding = enableReverseGeocoding,
        )
    }

    private fun configureTerminatedPersistence(args: Map<*, *>) {
        val adapter = args["adapter"] as? String
        val firebaseDatabaseUrl = args["databaseUrl"] as? String
        val httpEndpoint = args["endpointTemplate"] as? String
        val headers = args["headers"] as? Map<*, *>
        val headersRaw = headers?.entries?.joinToString("\n") { "${it.key}:${it.value}" }
        val collectorId = args["collectorId"] as? String

        TrackingPreferences(applicationContext).saveTerminatedPersistenceConfig(
            adapter = adapter,
            firebaseDatabaseUrl = firebaseDatabaseUrl,
            httpEndpointTemplate = httpEndpoint,
            httpHeaders = headersRaw,
            collectorId = collectorId,
        )
    }

    private fun syncPersistenceState(args: Map<*, *>) {
        val latitude = (args["latitude"] as? Number)?.toDouble() ?: return
        val longitude = (args["longitude"] as? Number)?.toDouble() ?: return
        val timestampMs = (args["timestampMs"] as? Number)?.toLong()
            ?: System.currentTimeMillis()

        TrackingPreferences(applicationContext).savePersistenceState(
            latitude = latitude,
            longitude = longitude,
            timestampMs = timestampMs,
        )
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

    private fun openBatteryOptimizationSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${applicationContext.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            applicationContext.startActivity(intent)
            true
        } catch (_: Exception) {
            try {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                applicationContext.startActivity(intent)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        LocationEventDispatcher.setEventSink { payload ->
            events?.success(payload)
        }
    }

    override fun onCancel(arguments: Any?) {
        LocationEventDispatcher.setEventSink(null)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        LocationEventDispatcher.setEventSink(null)
    }
}
