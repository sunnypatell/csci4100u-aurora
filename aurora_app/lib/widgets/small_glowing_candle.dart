import 'package:flutter/material.dart';

/// Small glowing candle used across the app (dashboard, settings, etc.).
class SmallGlowingCandle extends StatelessWidget {
  const SmallGlowingCandle({super.key});

  @override
  Widget build(BuildContext context) {
    const double outer = 44.0;
    const double middle = outer * 0.72;
    const double bodyWidth = outer * 0.36;
    const double bodyHeight = outer * 0.52;

    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: outer,
            height: outer,
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

          // Middle glow
          Container(
            width: middle,
            height: middle,
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
            width: bodyWidth,
            height: bodyHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF5),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF5C97B).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: bodyHeight * 0.12),
                // Flame (vertical gradient to suggest warmth).
                Container(
                  width: bodyWidth * 0.26,
                  height: bodyHeight * 0.24,
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
      ),
    );
  }
}
