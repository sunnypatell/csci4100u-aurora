import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
/// LandingScreen
///
/// Unauthenticated entry point presenting calming branding (glowing candle)
/// and a single path forward ("Begin") into the authentication flow.
/// Layout values are tuned for a centered, tranquil visual hierarchy with
/// intentional whitespace and gentle color palette.

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2), // reserve top vertical breathing room
              
              _buildGlowingCandle(),
              
              const SizedBox(height: 56), // generous gap isolates hero from title
              
              const Text(
                'Aurora',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2F2E2C),
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              
              const SizedBox(height: 20), // moderate spacing before tagline
              
              const Text(
                'A private space to pause, breathe, and\nunderstand your mind.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF6F6C66),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
              
              const SizedBox(height: 56), // strong emphasis separation before primary CTA
              
              _buildBeginButton(context),
              
              const SizedBox(height: 28), // subtle affirmation spacing
              
              const Text(
                'Your thoughts stay yours. Always.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6F6C66),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
              
              const Spacer(flex: 3), // bottom space ensures centered feel across device heights
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the layered glowing candle visual used as a subtle animated-like
  /// focal element without introducing actual animation (keeps initial build
  /// simple). Multiple concentric radial gradients simulate soft glow.
  Widget _buildGlowingCandle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow layer – broad, faint radial gradient.
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFF5C97B).withValues(alpha: 0.3),
                const Color(0xFFF5C97B).withValues(alpha: 0.0),
              ],
              stops: const [0.3, 1.0],
            ),
          ),
        ),
        // Middle glow layer – tighter gradient for depth.
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFF5C97B).withValues(alpha: 0.5),
                const Color(0xFFF5C97B).withValues(alpha: 0.0),
              ],
              stops: const [0.4, 1.0],
            ),
          ),
        ),
        // Candle body with inner flame accent.
        Container(
          width: 50,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF5),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF5C97B).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Flame (vertical gradient to suggest warmth).
              Container(
                width: 12,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFBF5),
                      Color(0xFFF5C97B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the primary CTA used to start the authentication flow.
  Widget _buildBeginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5C97B),
          foregroundColor: const Color(0xFF2F2E2C),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Begin reflection',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}