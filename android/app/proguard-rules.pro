# ─── Flutter Engine ────────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# ─── SQLite / Drift ───────────────────────────────────────────────────────────
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }
-dontwarn org.sqlite.**

# ─── path_provider ───────────────────────────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# ─── url_launcher ─────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

# ─── share_plus ───────────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# ─── pdf / printing (uses dart:ffi & native page rendering) ──────────────────
-keep class com.artifex.** { *; }
-keep class net.sf.** { *; }
-keep class com.print.** { *; }
-keep class io.github.ponnamkarthik.** { *; }
-keep class com.tilibrim.** { *; }
-dontwarn com.artifex.**

# ─── qr_flutter ───────────────────────────────────────────────────────────────
-keep class io.github.qr.** { *; }
-dontwarn io.github.qr.**

# ─── fl_chart ─────────────────────────────────────────────────────────────────
-keep class com.github.mikephil.** { *; }

# ─── Google Fonts ─────────────────────────────────────────────────────────────
-keep class com.google.fonts.** { *; }
-dontwarn com.google.fonts.**

# ─── General Kotlin / Coroutine ───────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# ─── General warnings to suppress ─────────────────────────────────────────────
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn okio.**
-dontwarn okhttp3.**
-dontwarn com.google.errorprone.**
