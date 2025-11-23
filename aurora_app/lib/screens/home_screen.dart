// HomeScreen (Deprecated)
// Placeholder retained for backward compatibility with early navigation code.
// Prefer `DashboardScreen`. Minimal logic provided; only sign-out action.
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
