import 'dart:ui' show ImageFilter;

/// DashboardScreen
///
/// Main post-authentication landing surface presenting quick navigation tiles
/// into primary feature areas (Journal, Resources, Help Near Me, Chat). Uses a
/// responsive `SliverGrid` (2 columns on narrow viewports, 4 on wide) and a
/// streamed profile document to render a contextual greeting. Sign-out and
/// settings are exposed via AppBar actions.
///
/// UX / Design notes:
/// - Grid delegates adapt aspect ratio to avoid overly tall tiles on desktop.
/// - Greeting chooses the most specific available identity field (displayName,
///   fullName, Firebase displayName, email fallback).
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
// settings_screen.dart is not used here; removed to satisfy analyzer
import 'aurora_shell.dart';
import '../widgets/small_glowing_candle.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _text =
      Color(0xFF2F2E2C); // neutral text used across app

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: SmallGlowingCandle()),
          ),
        ),
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text('You can sign back in any time.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );
              if (ok == true) await AuthService.instance.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface.withValues(alpha: 0.95),
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: true,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 920,
                    ), // keep layout nice on wide screens
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: uid != null
                          ? StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .snapshots(),
                              builder: (context, snap) {
                                if (snap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const _ProfileCard.loading();
                                }
                                if (snap.hasError) {
                                  return const _ProfileCard(name: 'Welcome');
                                }
                                final data = snap.data?.data();
                                final displayName =
                                    (data?['displayName'] as String?)?.trim();
                                final fullName =
                                    (data?['fullName'] as String?)?.trim();

                                final candidates = <String?>[
                                  displayName,
                                  fullName,
                                  user?.displayName,
                                  user?.email,
                                  'friend',
                                ];
                                final name = candidates.firstWhere(
                                  (v) => v != null && v.isNotEmpty,
                                  orElse: () => 'friend',
                                )!;

                                String capitalizeName(String raw) {
                                  if (raw.contains('@')) return raw;
                                  return raw
                                      .split(RegExp(r"\s+"))
                                      .map((w) => w.isEmpty
                                          ? w
                                          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
                                      .join(' ');
                                }

                                return _ProfileCard(
                                  name: 'Welcome back, ${capitalizeName(name)}',
                                );
                              },
                            )
                          : const _ProfileCard(name: 'Welcome'),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 12 + MediaQuery.of(context).padding.bottom,
                ),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final viewportWidth =
                        constraints.crossAxisExtent.clamp(280.0, 1200.0);
                    final isWide = viewportWidth >= 680;
                    final crossAxisCount = isWide ? 4 : 2;
                    // Give tiles a bit more vertical room on phones to avoid
                    // text overflow in languages or long titles.
                    final childAspectRatio = isWide ? 1.1 : 0.85;

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: childAspectRatio,
                      ),
                      delegate: SliverChildListDelegate.fixed([
                        _ActionTile(
                          icon: Icons.menu_book_rounded,
                          titleBuilder: (_) => 'Open Journal',
                          subtitle: 'Write and reflect',
                          onTap: () => AuroraShell.navigateTo(context, 1),
                        ),
                        _ActionTile(
                          icon: Icons.library_books_outlined,
                          titleBuilder: (_) => 'Resources',
                          subtitle: 'Learn coping skills',
                          onTap: () => AuroraShell.navigateTo(context, 2),
                        ),
                        _ActionTile(
                          icon: Icons.place_outlined,
                          titleBuilder: (_) => 'Help Near Me',
                          subtitle: 'Find local support',
                          onTap: () => AuroraShell.navigateTo(context, 3),
                        ),
                        _ActionTile(
                          icon: Icons.psychology_alt_outlined,
                          titleBuilder: (w) =>
                              w < 380 ? 'Aurora Chat' : 'Chat with Aurora',
                          subtitle: 'Supportive AI companion',
                          onTap: () => AuroraShell.navigateTo(context, 4),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small, private copy of the landing screen glowing candle used for the
/// dashboard AppBar. Kept identical in appearance but scaled down so it
/// doesn't interfere with AppBar actions.
// Moved to `lib/widgets/small_glowing_candle.dart` for reuse across screens.

/// Private animated glass profile card shown at top of dashboard.
/// Handles loading (skeleton shimmer substitute), greeting text and subtle
/// entrance scale animation.
class _ProfileCard extends StatelessWidget {
  final String? name;
  final bool isLoading;
  const _ProfileCard({this.name, this.isLoading = false});
  const _ProfileCard.loading() : this(name: null, isLoading: true);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surface = colorScheme.surface.withValues(alpha: 0.65);
    final border = colorScheme.primary.withValues(alpha: 0.16);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 22,
                  offset: Offset(0, 12),
                  color: Color(0x1664B5F6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.72),
                          colorScheme.primaryContainer.withValues(alpha: 0.58),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: isLoading
                      ? const _Skeleton(lines: 2)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name ?? 'Welcome',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: DashboardScreen._text,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Let’s take one gentle step today. 💙',
                              style: TextStyle(
                                fontSize: 14,
                                color: DashboardScreen._text
                                    .withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple placeholder skeleton used for loading the profile document.
/// Renders a configurable number of light bars (lines).
class _Skeleton extends StatelessWidget {
  final int lines;
  const _Skeleton({this.lines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (i) {
        final width = i == 0 ? 200.0 : 140.0;
        return Padding(
          padding: EdgeInsets.only(bottom: i == lines - 1 ? 0 : 8),
          child: Container(
            width: width,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }),
    );
  }
}

/// Reusable action tile representing a primary navigation target.
/// Applies layered gradients + backdrop blur for brand consistency.
///
/// [titleBuilder] receives current screen width so titles can shorten in
/// tight layouts (example: "Chat with Aurora" -> "Aurora Chat").
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String Function(double screenWidth) titleBuilder;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.titleBuilder,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surface = colorScheme.surface.withValues(alpha: 0.60);
    final border = colorScheme.primary.withValues(alpha: 0.14);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.transparent,
                child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.95),
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  color: surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                      color: colorScheme.primary.withValues(alpha: 0.09),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon pill
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.72),
                            colorScheme.primaryContainer.withValues(alpha: 0.58),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: Text(
                        titleBuilder(screenWidth),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: DashboardScreen._text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          color: DashboardScreen._text.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
