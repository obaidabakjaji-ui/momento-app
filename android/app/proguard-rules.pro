# =====================================================================
# Huddlex release ProGuard / R8 rules.
#
# Flutter's release build enables R8 by default. Without explicit -keep
# rules the shrinker can strip plugin classes that are referenced only via
# the Android manifest or reflection — most visibly the home-screen widget
# receiver and the home_widget / workmanager bridges.
#
# Anything called from the Android side (broadcast receivers, BG isolate
# entry points) needs to be preserved so the JVM can resolve it.
# =====================================================================

# Our widget receiver. AppWidgetProvider is referenced from manifest, but
# we keep the whole subclass + companion to be safe (R8 has been known to
# strip Kotlin companion init that the receiver depends on).
-keep class com.momento.momento.MomentoWidgetReceiver { *; }
-keep class com.momento.momento.MomentoWidgetReceiver$* { *; }

# home_widget plugin: bridges Flutter <-> AppWidgetProvider via shared
# prefs + broadcasts. The provider abstract class + plugin registrant must
# stay intact.
-keep class es.antonborri.home_widget.** { *; }
-dontwarn es.antonborri.home_widget.**

# workmanager plugin: the BG isolate callback is registered via Plugin
# registrant + a JNI entry-point. Strip nothing.
-keep class be.tramckrijte.workmanager.** { *; }
-dontwarn be.tramckrijte.workmanager.**

# Firebase Core / Firestore / Auth / Storage / Functions / Crashlytics /
# AppCheck — all use reflection or annotation processors that R8 can't
# always trace.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Camera plugin: native bridge for capture sessions.
-keep class io.flutter.plugins.camera.** { *; }
-dontwarn io.flutter.plugins.camera.**

# Flutter embedding + plugin registrants — keep everything that lives in
# io.flutter so plugin discovery on cold start can't be tree-shaken.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# androidx.glance — home_widget pulls it in for surface composition.
-keep class androidx.glance.** { *; }
-dontwarn androidx.glance.**

# Geolocator: reflection-based service binders for foreground location.
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# Anything the @pragma('vm:entry-point') annotation pins on the Dart side
# is exposed to JNI via the AOT snapshot — but R8 looks at the Kotlin/Java
# wrappers, so keep the standard interop classes.
-keep class io.flutter.embedding.engine.dart.DartExecutor { *; }
-keep class io.flutter.view.FlutterCallbackInformation { *; }
