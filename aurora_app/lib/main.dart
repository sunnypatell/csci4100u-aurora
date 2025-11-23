import 'package:flutter/material.dart';
/// main.dart
/// Application entry: initializes Flutter bindings, Firebase (per-platform
/// options), local notification service, then boots the root `AuroraApp`.
/// AuroraApp sets up global theming (Material 3 + seeded color scheme) and
/// provides a transparent SnackBar theme since we use a custom overlay toast.
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/landing_screen.dart';
// import 'screens/auth/login_screen.dart'; // not needed when Landing is the unauthenticated start
import 'screens/dashboard_screen.dart';
import 'screens/aurora_shell.dart';
import 'services/auth_service.dart';
import 'services/notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase for the current platform using FlutterFire generated options.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();
  // Schedule journal reminder if not already set (non-forced call).
  await NotificationService.instance.scheduleDailyJournalReminder();
  runApp(const AuroraApp());
}

class AuroraApp extends StatelessWidget {
  const AuroraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aurora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF5C97B),
          brightness: Brightness.light,
        ),
        snackBarTheme: const SnackBarThemeData(
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

/// _AuthGate
/// Listens to auth state stream to route either authenticated dashboard or
/// unauthenticated landing screen. Centralizes logic so deep widgets don't
/// need to embed auth listeners.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state while Firebase initializes/auth checks
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If signed in, show dashboard. If not, show landing page (user can proceed to login/signup).
        if (snapshot.hasData) {
          // Authenticated: show shell with bottom navigation across core areas.
          return const AuroraShell();
        }
        return const LandingScreen();
      },
    );
  }
}