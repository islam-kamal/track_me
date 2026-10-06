package com.example.nt_location_tracking.terminated

import android.content.Context
import com.google.firebase.FirebaseApp
import com.google.firebase.database.FirebaseDatabase

internal object FirebaseTerminatedWriter {
    fun write(
        context: Context,
        userId: String,
        payload: Map<String, Any?>,
        databaseUrl: String?,
    ) {
        ensureFirebaseInitialized(context)
        val database = if (!databaseUrl.isNullOrBlank()) {
            FirebaseDatabase.getInstance(databaseUrl)
        } else {
            FirebaseDatabase.getInstance()
        }

        val userRef = database.reference.child("users").child(userId)
        userRef.child("currentLocation").setValue(payload)
        userRef.child("locations").push().setValue(payload)
    }

    private fun ensureFirebaseInitialized(context: Context) {
        try {
            FirebaseApp.getInstance()
        } catch (_: IllegalStateException) {
            // The Flutter engine is gone after the app is swiped away. The
            // service process can still start Firebase from the app context.
            FirebaseApp.initializeApp(context)
        }
    }
}
