/// HomeScreen (Deprecated)
///
/// Lightweight placeholder retained for backward compatibility with early
/// navigation code and deep links that may still reference the original
/// route name. Prefer using `DashboardScreen` for any new navigation.
///
/// Only exposes a sign–out action and a message indicating deprecation so
/// contributors understand why this file still exists.
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Deprecated screen. Redirecting to dashboard...'),
            TextButton(
              onPressed: () async => AuthService.instance.signOut(),
              child: const Text('Sign out'),
            )
          ],
        ),
      ),
    );
  }
}
