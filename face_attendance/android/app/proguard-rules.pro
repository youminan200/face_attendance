# ==============================================================================
# Flutter / Google ML Kit / Camera ProGuard & R8 Optimization Rules
# ==============================================================================

# Flutter Core keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Services & ML Kit Face Detection
-keep class com.google.android.gms.internal.mlkit_vision_face.** { *; }
-keep class com.google.mlkit.vision.face.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**

# AndroidX Camera & CameraX
-keep class androidx.camera.core.** { *; }
-keep class androidx.camera.camera2.** { *; }
-keep class androidx.camera.lifecycle.** { *; }
-dontwarn androidx.camera.**

# SQLite / Sqflite plugin
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# JNI & Native Libraries
-keepclasseswithmembernames class * {
    native <methods>;
}

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
