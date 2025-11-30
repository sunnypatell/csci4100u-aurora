import 'package:flutter/material.dart';

/// Reusable glowing candle logo used across the app.
///
/// Accepts a `size` parameter which defines the overall width/height.
class GlowingCandle extends StatelessWidget {
  final double size;
  final bool useThemeColors;
  const GlowingCandle({super.key, this.size = 100, this.useThemeColors = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Default palette used on the landing screen; when useThemeColors is true
    // we blend with the colorScheme for better app cohesion on darker themes.
    final Color glowColor = useThemeColors
      ? theme.colorScheme.primary
      : const Color(0xFFF5C97B);
    final Color candleBody = useThemeColors ? theme.colorScheme.surface : const Color(0xFFFFFBF5);

    final double outer = size;
    final double middle = size * 0.72;
    final double bodyWidth = size * 0.36;
    final double bodyHeight = size * 0.52;

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
                  glowColor.withValues(alpha: 0.22),
                  glowColor.withValues(alpha: 0.0),
                ],
                stops: const [0.28, 1.0],
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
                  glowColor.withValues(alpha: 0.36),
                  glowColor.withValues(alpha: 0.0),
                ],
                stops: const [0.35, 1.0],
              ),
            ),
          ),

          // Candle body
          Container(
            width: bodyWidth,
            height: bodyHeight,
            decoration: BoxDecoration(
              color: candleBody,
              borderRadius: BorderRadius.circular(bodyWidth / 3),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.18),
                    blurRadius: size * 0.24,
                    spreadRadius: size * 0.03,
                  ),
                ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: bodyHeight * 0.12),
                // Flame
                Container(
                  width: bodyWidth * 0.26,
                  height: bodyHeight * 0.24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        candleBody,
                        glowColor.withValues(alpha: 0.9),
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
