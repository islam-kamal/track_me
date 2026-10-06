# WorkManager uses Room internally; keep generated DB implementation classes in release builds.
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keepclassmembers class androidx.work.impl.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker
-keep class * extends androidx.work.CoroutineWorker
-keep class * extends androidx.work.InputMerger

# Room (used by WorkManager)
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-keepclassmembers class * {
    @androidx.room.* <methods>;
}

# Plugin workers
-keep class com.example.nt_location_tracking.worker.** { *; }
-keep class com.example.nt_location_tracking.receiver.** { *; }
