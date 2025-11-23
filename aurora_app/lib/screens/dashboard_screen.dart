import 'dart:ui' show ImageFilter;
/// DashboardScreen
/// Main post-auth landing surface presenting quick navigation tiles into
/// primary feature areas (Journal, Resources, Help Near Me, Chat). Utilizes a
/// responsive SliverGrid to adapt tile count for wide layouts and streams the
/// user's profile document to render a friendly greeting. Sign-out and
/// settings available via AppBar actions.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import 'settings_screen.dart';
import 'journal_screen.dart';
import 'resources.dart';
import 'help_near_me.dart';
import 'chat.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _bg = Color(0xFFF5EFE7);
  static const _text = Color(0xFF2F2E2C);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: _text, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: _text),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: uid != null
                        ? StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const _ProfileCard.loading();
                              }
                              if (snap.hasError) {
                                return const _ProfileCard(name: 'Hello');
                              }
                              final data = snap.data?.data();
                              final displayName = (data?['displayName'] as String?)?.trim();
                              final fullName = (data?['fullName'] as String?)?.trim();
                              // Determine best display name candidate in priority order.
                              final candidates = <String?>[
                                displayName,
                                fullName,
                                user?.displayName,
                                user?.email,
                                'User',
                              ];
                              final name = candidates.firstWhere(
                                (v) => v != null && v.isNotEmpty,
                                orElse: () => 'User',
                              )!;
                              return _ProfileCard(name: 'Hello, $name');
                            },
                          )
                        : const _ProfileCard(name: 'Hello'),
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
                  final viewportWidth = constraints.crossAxisExtent.clamp(280.0, 1200.0);
                  final isWide = viewportWidth >= 680; // breakpoint for 4-column layout
                  final crossAxisCount = isWide ? 4 : 2;
                  final childAspectRatio = isWide ? 1.1 : 0.95;

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
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const JournalScreen()),
                        ),
                      ),
                      _ActionTile(
                        icon: Icons.library_books_outlined,
                        titleBuilder: (_) => 'Resources',
                        subtitle: 'Learn coping skills',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ResourcesPage()),
                        ),
                      ),
                      _ActionTile(
                        icon: Icons.place_outlined,
                        titleBuilder: (_) => 'Help Near Me',
                        subtitle: 'Find local support',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HelpNearMePage()),
                        ),
                      ),
                      _ActionTile(
                        icon: Icons.forum_outlined,
                        titleBuilder: (w) => w <= 360 ? 'Buddy Chat' : 'Chat with a Buddy',
                        subtitle: 'Community check-in',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CommunityChatPage()),
                        ),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String? name;
  final bool isLoading;
  const _ProfileCard({this.name, this.isLoading = false});
  const _ProfileCard.loading() : this(name: null, isLoading: true);

  @override
  Widget build(BuildContext context) {
    final surface = Colors.white.withValues(alpha: 0.55);
    const border = Color(0x33000000);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
              boxShadow: const [
                BoxShadow(blurRadius: 18, offset: Offset(0, 10), color: Color(0x14000000)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF2B8A0), Color(0xFF9AD1C1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.person_rounded, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: isLoading
                      ? const _Skeleton(lines: 2)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name ?? 'Hello',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: DashboardScreen._text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Here’s your hub. Pick an action to get started.',
                              style: TextStyle(
                                fontSize: 14,
                                color: DashboardScreen._text.withValues(alpha: 0.7),
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
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }),
    );
  }
}

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
    final surface = Colors.white.withValues(alpha: 0.6);
    const border = Color(0x2F000000);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.black12,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2F2E2C), Color(0xFF4C4946)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const Spacer(),
                  Text(
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.2,
                      color: DashboardScreen._text.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
