# Flutter ProGuard & R8 Optimization Rules for DUKA Uganda
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Drift and SQLite reflection safe
-keep class org.sqlite.** { *; }
-keep class com.arthenica.ffmpegkit.** { *; }

# Optimizations
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn okio.**
