import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/widget_service.dart';
import 'services/widget_background_task.dart';
import 'services/locale_service.dart';
import 'models/app_user.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics: catch everything Flutter and Dart can throw and ship it
  // to the Firebase console. In debug builds we still record errors but
  // they're flagged so the dashboard doesn't pollute prod numbers.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // App Check: attestation that requests come from the real Huddlex app.
  // In debug builds we use the debug provider — the token it prints to
  // stdout has to be added to Firebase Console (App Check → Apps → Manage
  // debug tokens) so the backend will accept it. In release builds we use
  // App Attest on iOS and Play Integrity on Android. Apple Developer
  // Program approval + App Attest capability are required for App Attest
  // to work on real devices; until that's set up, release iOS will fall
  // back to DeviceCheck (still real attestation, just less granular).
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? AndroidDebugProvider()
        : AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? AppleDebugProvider()
        : AppleAppAttestWithDeviceCheckFallbackProvider(),
  );

  await WidgetService().initialize();
  await LocaleService.instance.load();

  // Schedule a periodic widget refresh so the home-screen widget stays
  // fresh even when the user hasn't opened the app for a while. Android
  // honours the periodicity reliably (WorkManager). iOS is opportunistic —
  // Apple decides when to actually run BGTasks, so it can be hours apart;
  // that's expected, not a bug.
  await Workmanager().initialize(widgetBackgroundCallback);
  await Workmanager().registerPeriodicTask(
    widgetRefreshTaskName,
    widgetRefreshTaskName,
    frequency: const Duration(hours: 1),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  runApp(const MomentoApp());
}

class MomentoApp extends StatelessWidget {
  const MomentoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocaleService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Huddlex',
          theme: MomentoTheme.light,
          debugShowCheckedModeBanner: false,
          locale: LocaleService.instance.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!authSnap.hasData) return const AuthScreen();

        // Hard gate: every email/password account has to confirm with the
        // 6-digit code before getting any further. Google accounts come back
        // with emailVerified=true automatically so they pass straight through.
        if (!authSnap.data!.emailVerified) {
          return const VerifyEmailScreen();
        }

        // Signed in + verified — gate on whether the user has finished onboarding.
        return StreamBuilder<AppUser?>(
          stream: FirestoreService().watchUser(authSnap.data!.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final user = userSnap.data;
            // If the doc hasn't been created yet (race after sign-up), keep
            // waiting rather than flashing onboarding then home.
            if (user == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!user.hasSeenOnboarding) return const OnboardingScreen();
            return const HomeScreen();
          },
        );
      },
    );
  }
}
