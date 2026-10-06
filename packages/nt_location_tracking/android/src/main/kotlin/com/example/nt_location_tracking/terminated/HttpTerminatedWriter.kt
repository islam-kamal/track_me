package com.example.nt_location_tracking.terminated

import android.util.Log
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

internal object HttpTerminatedWriter {
    private const val TAG = "NtLocationTracking"
    private const val CONNECT_TIMEOUT_MS = 30_000
    private const val READ_TIMEOUT_MS = 30_000

    fun write(
        userId: String,
        payload: Map<String, Any?>,
        endpointTemplate: String?,
        headersRaw: String?,
    ): Boolean {
        val template = endpointTemplate
        if (template.isNullOrBlank()) {
            Log.w(TAG, "Terminated save skipped: missing HTTP endpoint template")
            return false
        }

        val endpoint = template.replace("{subjectId}", userId)
        return try {
            val connection = (URL(endpoint).openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                doOutput = true
                connectTimeout = CONNECT_TIMEOUT_MS
                readTimeout = READ_TIMEOUT_MS
                setRequestProperty("Content-Type", "application/json")
                parseHeaders(headersRaw).forEach { (key, value) ->
                    setRequestProperty(key, value)
                }
            }

            val json = JSONObject(payload.filterValues { it != null }).toString()
            connection.outputStream.use { stream ->
                stream.write(json.toByteArray(Charsets.UTF_8))
            }

            val code = connection.responseCode
            if (code in 200..299) {
                Log.i(TAG, "Terminated HTTP save succeeded ($code)")
                true
            } else {
                Log.w(TAG, "Terminated HTTP save failed ($code)")
                false
            }
        } catch (error: Exception) {
            Log.w(TAG, "Terminated HTTP save failed: ${error.message}")
            false
        }
    }

    private fun parseHeaders(raw: String?): Map<String, String> {
        if (raw.isNullOrBlank()) {
            return emptyMap()
        }
        return raw.lineSequence()
            .mapNotNull { line ->
                val index = line.indexOf(':')
                if (index <= 0) {
                    null
                } else {
                    line.substring(0, index).trim() to line.substring(index + 1).trim()
                }
            }
            .toMap()
    }
}
