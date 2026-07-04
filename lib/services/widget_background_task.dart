import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../firebase_options.dart';
import 'widget_service.dart';

/// Identifier for the periodic widget-refresh task we schedule with
/// Workmanager. Used as both the unique work name and the task name the
/// callback dispatcher matches on.
const String widgetRefreshTaskName = 'huddlex-widget-refresh';

/// Entry point for the background isolate. Workmanager calls this when the
/// scheduled task fires. The vm:entry-point pragma is required because the
/// background isolate can't see anything tree-shaken away from the main
/// isolate.
@pragma('vm:entry-point')
void widgetBackgroundCallback() {
  Workmanager().executeTask((task, _) async {
    if (task != widgetRefreshTaskName) return true;
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await WidgetService().refreshForUser(user.uid);
      }
    } catch (e, st) {
      // Background isolate — no UI to surface failures. Log so it shows up
      // in adb logcat / Console.app if the user is debugging.
      debugPrint('Widget refresh failed: $e\n$st');
    }
    return true;
  });
}
