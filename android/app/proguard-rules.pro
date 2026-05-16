# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Drift / sqlite3 — JNI-loaded entry points and reflection-driven query
# parser internals.
-keep class org.sqlite.** { *; }
-keep class org.sqlite3.** { *; }
-keep class com.simolus3.** { *; }

# Firebase / play-services — Firebase Auth + Firestore + Crashlytics +
# Analytics use Smart-Lock-style reflection.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
    @com.google.firebase.firestore.PropertyName <methods>;
}
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# RevenueCat — internal POJOs serialised via reflection.
-keep class com.revenuecat.purchases.** { *; }

# OneSignal
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# Geolocator / sensors_plus — platform channels.
-keep class com.baseflow.geolocator.** { *; }
-keep class dev.fluttercommunity.plus.sensors.** { *; }

# flutter_map / latlong2 / proj4dart — no obfuscation surprises in the
# projection code paths.
-keep class org.openstreetmap.** { *; }

# Kotlin metadata
-keep class kotlin.Metadata { *; }
-keep class kotlin.coroutines.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Keep model classes used as Firestore documents — naming preserved so
# the property names match Firestore field names.
-keep class com.bytse.drive_rank.** { *; }

# Strip android.util.Log on release for marginal binary size win + zero
# console leaks in production builds. Comment out if you need release
# logs for crash repro.
-assumenosideeffects class android.util.Log {
    public static *** v(...);
    public static *** d(...);
    public static *** i(...);
}
