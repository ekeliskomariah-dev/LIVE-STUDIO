# Zack Live Studio ProGuard rules

# Kotlin
-dontwarn kotlin.**

# Coroutines
-keepclassmembers class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Room
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-dontwarn androidx.room.paging.**

# CameraX
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# MediaPipe
-keep class com.google.mediapipe.** { *; }
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.mediapipe.**
-dontwarn com.google.protobuf.**

# OkHttp / Okio
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Compose
-keep class androidx.compose.** { *; }

# Keep app data classes used by Room / serialization
-keep class com.zack.livestudio.storage.entity.** { *; }
-keep class com.zack.livestudio.scenes.model.** { *; }
-keep class com.zack.livestudio.streaming.profile.** { *; }
-keep class com.zack.livestudio.chat.** { *; }

# Keep enum values for serialization
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
