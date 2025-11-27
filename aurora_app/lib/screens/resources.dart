import 'package:flutter/material.dart';

/// ResourcesPage
/// Curated self-help & support destination offering cards that route into
/// focused help pages (Eating Disorders, ADHD, Anxiety/Depression, Other
/// Supports). Includes a subtle breathing animation header to reinforce calm
/// atmosphere. Hotline action currently placeholder—replace with real campus
/// or community support contacts.
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/aurora_snackbar.dart';
import '../services/remote_resource_service.dart';
import '../screens/resources/eat_dis.dart';

/// Entry widget (use in your routes or Navigator.push)
class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breatheCtrl;
  late final Animation<double> _breathe;
  late Future<Quote> _quoteFuture; // Cached future to allow refresh
  bool _justRefreshed = false; // Track refresh to show success snackbar once

  @override
  void initState() {
    super.initState();
    // Gentle “breathing bubble” animation for a calming header.
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _breathe = Tween(begin: 0.92, end: 1.08)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_breatheCtrl);
    _quoteFuture = RemoteResourceService.instance.fetchRandomQuote();
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EFE7),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Resources',
          style: TextStyle(
            color: Color(0xFF2F2E2C),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF2F2E2C)),
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface.withValues(alpha: 0.95),
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<Quote>(
            future: _quoteFuture,
            builder: (context, snap) {
              final quote = snap.data;
              if (snap.connectionState == ConnectionState.done &&
                  _justRefreshed) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final isFallback = quote?.isFallback ?? false;
                  if (isFallback) {
                    showAuroraSnackBar(
                      context,
                      'Network issue – showing fallback quote',
                      variant: AuroraSnackVariant.alert,
                    );
                  } else {
                    showAuroraSnackBar(context, 'Quote refreshed ✓',
                        variant: AuroraSnackVariant.success);
                  }
                });
                _justRefreshed = false;
              }
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _QuoteCard(
                            quote: quote,
                            loading:
                                snap.connectionState != ConnectionState.done,
                            onRefresh: _refreshQuote,
                          ),
                          const SizedBox(height: 16),
                          // Calming header with breathing bubble
                          Row(
                            children: [
                              ScaleTransition(
                                scale: _breathe,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.primary
                                            .withValues(alpha: 0.28),
                                        colorScheme.tertiary
                                            .withValues(alpha: 0.28),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.18),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text("🫧",
                                      style: TextStyle(fontSize: 18)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "You’re safe here",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Pick what you need right now. Small steps count. 💙",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.3),
                          ),
                          const SizedBox(height: 16),
                          const _TipChip(
                              label: "Tip: Inhale 4 • Hold 4 • Exhale 4",
                              icon: "🌿"),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            constraints.crossAxisExtent > 780 ? 3 : 2;
                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.08,
                          ),
                          delegate: SliverChildListDelegate.fixed([
                            ResourceCard(
                              title: "Eating Disorders",
                              subtitle: "Gentle guidance & support",
                              emoji: "🥣",
                              gradientA:
                                  Colors.pink.shade200.withValues(alpha: 0.35),
                              gradientB: Colors.purple.shade200
                                  .withValues(alpha: 0.35),
                              onTap: () =>
                                  _open(context, const EatingDisordersHelpPage()),
                            ),
                            ResourceCard(
                              title: "ADHD Help",
                              subtitle: "Focus tools & coping tips",
                              emoji: "🧠",
                              gradientA:
                                  Colors.blue.shade200.withValues(alpha: 0.35),
                              gradientB:
                                  Colors.green.shade200.withValues(alpha: 0.35),
                              onTap: () => _open(context, const ADHDHelpPage()),
                            ),
                            ResourceCard(
                              title: "Anxiety",
                              subtitle: "Grounding, calm, connection",
                              emoji: "🌊",
                              gradientA:
                                  Colors.teal.shade200.withValues(alpha: 0.35),
                              gradientB:
                                  Colors.cyan.shade200.withValues(alpha: 0.35),
                              onTap: () => _open(
                                  context, const AnxietyDepressionHelpPage()),
                            ),
                            ResourceCard(
                              title: "More Supports",
                              subtitle: "Hotlines, journaling, music",
                              emoji: "🧩",
                              gradientA:
                                  Colors.amber.shade200.withValues(alpha: 0.35),
                              gradientB: Colors.indigo.shade200
                                  .withValues(alpha: 0.35),
                              onTap: () =>
                                  _open(context, const OtherSupportsPage()),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _refreshQuote() {
    setState(() {
      _quoteFuture = RemoteResourceService.instance.fetchRandomQuote();
      _justRefreshed = true;
    });
    showAuroraSnackBar(context, 'Refreshing...',
        variant: AuroraSnackVariant.info);
  }

  void _open(BuildContext context, Widget page) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, a, b) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
          child: page,
        ),
      ),
    );
  }
}

/// Friendly tip chip with a subtle hover/press animation.
class _TipChip extends StatefulWidget {
  final String label;
  final String icon;
  const _TipChip({required this.label, required this.icon});

  @override
  State<_TipChip> createState() => _TipChipState();
}

class _TipChipState extends State<_TipChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A soft, glassy card that feels friendly and low-stress.
class ResourceCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final Color gradientA;
  final Color gradientB;
  final VoidCallback onTap;

  const ResourceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradientA,
    required this.gradientB,
    required this.onTap,
  });

  @override
  State<ResourceCard> createState() => _ResourceCardState();
}

class _ResourceCardState extends State<ResourceCard> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : (_hovering ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  widget.gradientA,
                  widget.gradientB,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
              boxShadow: [
                if (_hovering)
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.12),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Semantics(
              button: true,
              label: widget.title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Text(widget.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.arrow_forward_rounded,
                          size: 18, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(
                        "Open",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
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

/// Displays a fetched motivational quote with graceful loading & fallback.
class _QuoteCard extends StatelessWidget {
  final Quote? quote;
  final bool loading;
  final VoidCallback onRefresh;
  const _QuoteCard(
      {required this.quote, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(loading),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: loading
            ? const Row(
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Fetching a gentle thought...',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Encouragement',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '“${quote?.text ?? 'Keep going.'}”',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: (quote?.isFallback ?? false)
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '- ${quote?.author ?? 'Unknown'}${(quote?.isFallback ?? false) ? ' (fallback)' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}

/* --------------------------- Destination pages --------------------------- */
/* Replace the placeholder bodies with your actual content (articles, links,
   exercises, hotlines, StreamBuilders to Firestore, etc.) */

class ADHDHelpPage extends StatelessWidget {
  const ADHDHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleHelpScaffold(
      title: "ADHD Help",
      emoji: "🧠",
      bullets: [
        "Two-minute start: pick one tiny action and begin.",
        "Body-double timer and noise options.",
        "Task-break-reward cycles and routine builders.",
      ],
      accent: Colors.green,
    );
  }
}

class AnxietyDepressionHelpPage extends StatelessWidget {
  const AnxietyDepressionHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleHelpScaffold(
      title: "Anxiety & Depression",
      emoji: "🌊",
      bullets: [
        "Grounding (5-4-3-2-1) & calm breathing guides.",
        "Friendly journaling prompts and mood check-ins.",
        "When to reach out—hotlines and campus/community care.",
      ],
      accent: Colors.teal,
    );
  }
}

class OtherSupportsPage extends StatelessWidget {
  const OtherSupportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleHelpScaffold(
      title: "More Supports",
      emoji: "🧩",
      bullets: [
        "Study stress, sleep, grief, substance use resources.",
        "Music & nature soundscapes for quick reset.",
        "Community groups, peer listeners, and text lines.",
      ],
      accent: Colors.indigo,
    );
  }
}

/// Shared simple scaffold used by the 4 destination pages
class _SimpleHelpScaffold extends StatelessWidget {
  final String title;
  final String emoji;
  final List<String> bullets;
  final Color accent;

  const _SimpleHelpScaffold({
    required this.title,
    required this.emoji,
    required this.bullets,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text("$emoji  $title"),
        backgroundColor: cs.surface,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2F2E2C)),
          tooltip: 'Back to Dashboard',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Container(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.30)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "You’re not alone. Let’s take this one step at a time.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  "If anything here feels overwhelming, pause, sip some water, and come back when ready.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final item in bullets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.star_rounded, color: accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          FilledButton.icon(
            icon: const Icon(Icons.call_rounded),
            onPressed: () => _launchSupport(context),
            label: const Text("Talk to someone"),
          ),
        ],
      ),
    );
  }

  /// Launches preferred support path: attempts campus mental health page
  /// first (browser) then falls back to direct phone dial invocation for a
  /// provincial mental health helpline. If neither can launch, surfaces a
  /// snackbar with the number so the user can call manually. In production
  /// you may externalize these contacts and localize per region.
  Future<void> _launchSupport(BuildContext context) async {
    const campusUrl =
        'https://studentservices.ontariotechu.ca/current-students/health-and-wellness/i-am-in-distress/index.php';
    const hotlineNumber = '+1-866-531-2600'; // ConnexOntario (example)
    final hotlineUri = Uri(scheme: 'tel', path: hotlineNumber);

    try {
      // Try campus wellness page first
      final campusUri = Uri.parse(campusUrl);
      if (await canLaunchUrl(campusUri)) {
        await launchUrl(campusUri, mode: LaunchMode.externalApplication);
        if (!context.mounted) return;
        showAuroraSnackBar(context, 'Opening campus wellness resources…',
            variant: AuroraSnackVariant.success);
        return;
      }
    } catch (_) {/* ignore */}
    try {
      if (await canLaunchUrl(hotlineUri)) {
        await launchUrl(hotlineUri);
        if (!context.mounted) return;
        showAuroraSnackBar(context, 'Dialing mental health support…',
            variant: AuroraSnackVariant.success, icon: Icons.call_rounded);
        return;
      }
    } catch (_) {/* ignore */}
    // Fallback snackbar if nothing could launch.
    if (!context.mounted) return;
    showAuroraSnackBar(context, 'Call $hotlineNumber for mental health support',
        variant: AuroraSnackVariant.info, icon: Icons.call_rounded);
  }
}
