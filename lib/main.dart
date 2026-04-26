import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/widget_service.dart';
import 'models/app_user.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await WidgetService().initialize();
  runApp(const MomentoApp());
}

class MomentoApp extends StatelessWidget {
  const MomentoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Momento',
      theme: MomentoTheme.light,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
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
