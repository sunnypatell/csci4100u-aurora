import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EFE7),
        elevation: 0,
        title: const Text(
          'Aurora',
          style: TextStyle(color: Color(0xFF2F2E2C)),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await AuthService.instance.signOut();
            },
            icon: const Icon(Icons.logout, color: Color(0xFF2F2E2C)),
            label: const Text(
              'Sign out',
              style: TextStyle(color: Color(0xFF2F2E2C)),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You\'re signed in',
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFF2F2E2C),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.displayName?.isNotEmpty == true
                  ? 'Welcome, ${user!.displayName}!'
                  : (user?.email ?? 'Anonymous'),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6F6C66),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
