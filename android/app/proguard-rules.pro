# WorkManager + Room (required for release builds with R8)
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keepclassmembers class androidx.work.impl.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker
-keep class * extends androidx.work.CoroutineWorker

-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
