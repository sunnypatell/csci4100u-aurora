import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/landing_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase only after running flutterfire configure which
  // replaces the placeholder firebase_options.dart with real values.
  try {
    // When generated, firebase_options.dart will expose proper options and a flag.
    // Here we check placeholder flag to avoid initializing with empty values.
    // Replace this logic with: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (DefaultFirebaseOptions.isConfigured) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    // Safe to continue without Firebase for non-auth flows until configured.
    debugPrint('Firebase init skipped: $e');
  }
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
      ),
      home: const LandingScreen(),
    );
  }
}