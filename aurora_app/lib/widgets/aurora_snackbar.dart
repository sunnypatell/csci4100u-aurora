import 'package:flutter/material.dart';

/// Aurora Snackbar Overlay
/// Provides a cross-platform, theme-consistent toast / snackbar replacement.
/// Rationale: default Material SnackBar renders a dark bar on web that clashes
/// with the calm light palette. This overlay implementation allows custom
/// glassy styling, variant-driven iconography, entrance / exit animations, and
/// now: FIFO queueing + tap-to-dismiss. Multiple rapid calls are queued and
/// shown sequentially. User can dismiss early by tapping the snackbar.
/// Use `showAuroraSnackBar(context, message, variant: ...)` instead of the
/// ScaffoldMessenger API throughout the app.

/// Variants for Aurora snackbars.
enum AuroraSnackVariant { success, error, info, alert }

OverlayEntry? _currentAuroraSnack;
OverlayState? _overlayState; // store overlay directly to avoid disposed context lookups
final List<_QueuedSnack> _snackQueue = [];

class _QueuedSnack {
  final String message;
  final IconData icon;
  final Color accent;
  final Duration duration;
  _QueuedSnack(this.message, this.icon, this.accent, this.duration);
}

/// Shows a custom overlay-based snackbar/toast that is visually consistent
/// across platforms (avoids Material default dark bar on web).
void showAuroraSnackBar(
  BuildContext context,
  String message, {
  AuroraSnackVariant variant = AuroraSnackVariant.success,
  IconData? icon,
  Color? accent,
  Duration duration = const Duration(seconds: 3),
}) {
  icon ??= _iconFor(variant);
  accent ??= _accentFor(variant);
  // Acquire overlay (prefer root for stability across routes).
  final overlay = Overlay.of(context, rootOverlay: true);
  if (overlay == null) return;
  _overlayState = overlay;

  if (_currentAuroraSnack != null) {
    _snackQueue.add(_QueuedSnack(message, icon!, accent!, duration));
    return;
  }
  _displaySnack(_QueuedSnack(message, icon!, accent!, duration));
}

void _displaySnack(_QueuedSnack snack) {
  final overlay = _overlayState;
  if (overlay == null || !overlay.mounted) return;

  _currentAuroraSnack?.remove();

  final entry = OverlayEntry(
    builder: (ctx) => _AuroraSnackOverlay(
      message: snack.message,
      icon: snack.icon,
      accent: snack.accent,
      duration: snack.duration,
      onClose: () {
        _currentAuroraSnack?.remove();
        _currentAuroraSnack = null;
        if (_snackQueue.isNotEmpty) {
          final next = _snackQueue.removeAt(0);
          WidgetsBinding.instance.addPostFrameCallback((_) => _displaySnack(next));
        }
      },
    ),
  );
  overlay.insert(entry);
  _currentAuroraSnack = entry;
}

IconData _iconFor(AuroraSnackVariant v) {
  switch (v) {
    case AuroraSnackVariant.success:
      return Icons.check_rounded;
    case AuroraSnackVariant.error:
      return Icons.error_outline_rounded;
    case AuroraSnackVariant.info:
      return Icons.info_rounded;
    case AuroraSnackVariant.alert:
      return Icons.warning_rounded;
  }
}

Color _accentFor(AuroraSnackVariant v) {
  switch (v) {
    case AuroraSnackVariant.success:
      return const Color(0xFF1B7F3B); // green
    case AuroraSnackVariant.error:
      return const Color(0xFFB3261E); // red
    case AuroraSnackVariant.info:
      return const Color(0xFF2F6FED); // blue
    case AuroraSnackVariant.alert:
      return const Color(0xFF9C6F00); // amber/brown
  }
}

class _AuroraSnackContent extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color accent;
  const _AuroraSnackContent({
    required this.message,
    required this.icon,
    required this.accent,
  });

  Color _darken(Color c, [double amount = .22]) {
    final hsl = HSLColor.fromColor(c);
    final h = hsl.hue;
    final s = hsl.saturation;
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return HSLColor.fromAHSL(1.0, h, s, l).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final base = accent;
    final darker = _darken(base);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFE9F5EE),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Bottom accent bar
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: darker,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 18, 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: base.withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Icon(icon, color: base, size: 20),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
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

class _AuroraSnackOverlay extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color accent;
  final Duration duration;
  final VoidCallback onClose;

  const _AuroraSnackOverlay({
    required this.message,
    required this.icon,
    required this.accent,
    required this.duration,
    required this.onClose,
  });

  @override
  State<_AuroraSnackOverlay> createState() => _AuroraSnackOverlayState();
}

class _AuroraSnackOverlayState extends State<_AuroraSnackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(_fade);
    _ctrl.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (!_ctrl.isAnimating && mounted) {
      _ctrl.reverse().then((_) {
        if (mounted) widget.onClose();
      });
    } else if (mounted) {
      _ctrl.reverse().then((_) {
        if (mounted) widget.onClose();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 16 + safeBottom,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => Opacity(
          opacity: _fade.value,
          child: FractionalTranslation(
            translation: _slide.value,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: GestureDetector(
                  onTap: _dismiss, // tap-to-dismiss
                  behavior: HitTestBehavior.translucent,
                  child: _AuroraSnackContent(
                    message: widget.message,
                    icon: widget.icon,
                    accent: widget.accent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
