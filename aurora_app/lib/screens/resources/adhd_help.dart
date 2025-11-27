// adhd_help.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

// Aurora snackbars
import 'package:aurora_app/widgets/aurora_snackbar.dart';

class ADHDHelpPage extends StatefulWidget {
  const ADHDHelpPage({super.key});

  @override
  State<ADHDHelpPage> createState() => _ADHDHelpPageState();
}

class _ADHDHelpPageState extends State<ADHDHelpPage>
    with TickerProviderStateMixin {
  //body-doubling focus timer
  int _focusMinutes = 10;
  int _focusRemainingSeconds = 0;
  bool _focusActive = false;
  Timer? _focusTimer;

  final List<int> _presetDurations = [10, 20, 45];

  double get _focusProgress {
    if (!_focusActive || _focusMinutes == 0) return 0;
    final totalSeconds = _focusMinutes * 60;
    final done = totalSeconds - _focusRemainingSeconds;
    return (done / totalSeconds).clamp(0.0, 1.0);
  }

  String get _focusText {
    if (!_focusActive) {
      return "Pick a duration and tap Start. I’ll sit with you while you do just one thing.";
    }
    if (_focusRemainingSeconds <= 0) {
      return "You did it. Even if you paused, you still showed up.";
    }
    if (_focusRemainingSeconds > 60) {
      final mins = (_focusRemainingSeconds / 60).ceil();
      return "Stay with me for about $mins more minute${mins > 1 ? "s" : ""}. Tiny steps count.";
    }
    return "Less than a minute left! You’re allowed to finish gently or pause.";
  }

  void _startFocusTimer() {
    if (_focusActive) return;
    _focusRemainingSeconds = _focusMinutes * 60;
    setState(() => _focusActive = true);

    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _focusRemainingSeconds--;
        if (_focusRemainingSeconds <= 0) {
          _focusActive = false;
          _focusRemainingSeconds = 0;
          timer.cancel();
          showAuroraSnackBar(
            context,
            "Focus block done – you showed up, that matters 💙",
            variant: AuroraSnackVariant.success,
          );
        }
      });
    });
  }

  void _stopFocusTimer() {
    _focusTimer?.cancel();
    setState(() {
      _focusActive = false;
      _focusRemainingSeconds = 0;
    });
  }

  // -----------------------------
  // TASK BREAKDOWN WIZARD
  // -----------------------------
  final TextEditingController _taskController = TextEditingController();
  List<String> _taskSteps = [];

  void _breakTask() {
    final task = _taskController.text.trim();
    if (task.isEmpty) {
      showAuroraSnackBar(
        context,
        "Type one task you’re stuck on first.",
        variant: AuroraSnackVariant.info,
      );
      return;
    }

    // Super simple heuristic; you can later make this smarter
    final lower = task.toLowerCase();
    final List<String> steps = [];

    steps.add("➊ Make the task concrete: \"$task\"");

    if (lower.contains("room") || lower.contains("clean")) {
      steps.addAll([
        "➋ Set a 5–10 minute timer – you only commit to that.",
        "➌ Pick up visible trash and toss it.",
        "➍ Put clothes in one pile or laundry basket.",
        "➎ Clear one surface (desk / nightstand), not the whole room.",
      ]);
    } else if (lower.contains("assignment") ||
        lower.contains("essay") ||
        lower.contains("report")) {
      steps.addAll([
        "➋ Open the file or create a blank doc — that’s a valid step.",
        "➌ Write a messy list of ideas or bullet points.",
        "➍ Turn one bullet into 2–3 full sentences.",
        "➎ Save the file and name it clearly so it’s easy to find later.",
      ]);
    } else {
      steps.addAll([
        "➋ Ask: what’s the very first visible action? (e.g., open tab, find file, pick up item).",
        "➌ Do just that one action. Then pause and notice you did it.",
        "➍ Decide the next tiny action and repeat.",
      ]);
    }

    setState(() => _taskSteps = steps);
  }

  // -----------------------------
  // MICRO-START BUTTON
  // -----------------------------
  final List<String> _microActions = [
    "Open the tab or app you need.",
    "Drink a sip of water and take one deep breath.",
    "Write three messy words related to your task.",
    "Put your phone face down for two minutes.",
    "Clear just one small spot on your desk.",
    "Reply to one message or email.",
    "Stand up, stretch, then sit back down with your task.",
  ];

  String? _currentMicroAction;

  void _shuffleMicroAction() {
    _currentMicroAction ??= _microActions.first;
    _currentMicroAction = (_microActions.toList()..shuffle()).first;
    setState(() {});
  }

  // -----------------------------
  // NOISE TOOL (links only)
  // -----------------------------
  final Map<String, String> _noiseLinks = {
    "Soft rain": "https://www.youtube.com/results?search_query=rain+sounds",
    "Brown noise": "https://www.youtube.com/results?search_query=brown+noise",
    "Lo-fi beats": "https://www.youtube.com/results?search_query=lofi+beats",
    "Cafe ambience":
        "https://www.youtube.com/results?search_query=cafe+ambience",
  };

  Future<void> _openNoise(String label, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        showAuroraSnackBar(
          context,
          "Opening $label in your browser…",
          variant: AuroraSnackVariant.success,
        );
        return;
      }
    } catch (_) {}
    showAuroraSnackBar(
      context,
      "Couldn’t open $label. You can search it manually too.",
      variant: AuroraSnackVariant.alert,
    );
  }

  // -----------------------------
  // MOOD / ENERGY CHECK-IN
  // -----------------------------
  final List<String> _states = [
    "Low energy",
    "Overstimulated",
    "Understimulated",
    "Foggy",
    "Anxious",
    "Motivated",
  ];

  final Map<String, String> _stateSupport = {
    "Low energy":
        "Your job is to do the gentle version, not the perfect version. One tiny action + lots of kindness.",
    "Overstimulated":
        "Try lowering noise, dimming screens, and doing one grounding action. You can return to tasks slowly.",
    "Understimulated":
        "A bit of movement, upbeat noise, or a timer race with yourself can help create momentum.",
    "Foggy":
        "Pick something low-stakes and mechanical first (sorting files, tidying one corner) to warm up your brain.",
    "Anxious":
        "You’re allowed to pause. Slow down your breathing, then choose the least scary next step.",
    "Motivated":
        "Ride the wave, but don’t burn out. Pick 1–3 priorities, not 10.",
  };

  String? _selectedState;

  // -----------------------------
  // ROUTINE BUILDER
  // -----------------------------
  bool _rDrinkWater = true;
  bool _rOpenPlanner = false;
  bool _rCheckCalendar = false;
  bool _r10MinFocus = false;
  bool _rShortWalk = false;
  bool _rPackBag = false;

  List<String> get _routineItems {
    final list = <String>[];
    if (_rDrinkWater) list.add("Drink a glass of water");
    if (_rOpenPlanner) list.add("Open planner / to-do list");
    if (_rCheckCalendar) list.add("Glance at today’s calendar");
    if (_r10MinFocus) list.add("Do one 10-minute focus block");
    if (_rShortWalk) list.add("Take a 3–5 minute movement break");
    if (_rPackBag) list.add("Pack bag / prepare items for tomorrow");
    return list;
  }

  // -----------------------------
  // “TEXT YOURSELF” QUICK NOTES
  // -----------------------------
  final TextEditingController _noteController = TextEditingController();
  final List<String> _notes = [];

  void _addNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty) {
      showAuroraSnackBar(
        context,
        "Type a quick thought or reminder first.",
        variant: AuroraSnackVariant.info,
      );
      return;
    }
    setState(() {
      _notes.insert(0, text);
      _noteController.clear();
    });
  }

  // -----------------------------
  // VISUAL / ANIMATION
  // -----------------------------
  late final AnimationController _bgCtrl;
  late final AnimationController _pixelCtrl;
  final ScrollController _scrollController = ScrollController();
  bool _showPill = false;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);

    _pixelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _scrollController.addListener(() {
      final show = _scrollController.offset > 140;
      if (show != _showPill) {
        setState(() => _showPill = show);
      }
    });
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _bgCtrl.dispose();
    _pixelCtrl.dispose();
    _scrollController.dispose();
    _taskController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // -----------------------------
  // BUILD
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "🧠  ADHD Help",
          style: TextStyle(color: Color(0xFF12385C)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF12385C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (context, _) {
          final t = _bgCtrl.value;
          final c1 =
              Color.lerp(const Color(0xFFE3F2FD), const Color(0xFFE0F7FA), t)!;
          final c2 =
              Color.lerp(const Color(0xFFD1C4E9), const Color(0xFFB3E5FC), t)!;
          final c3 =
              Color.lerp(const Color(0xFFE8EAF6), const Color(0xFFE0F2F1), t)!;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c1, c2, c3],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  _FloatingPixels(animation: _pixelCtrl),
                  _buildContent(),
                  if (_showPill)
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 350),
                          opacity: _showPill ? 1 : 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF64B5F6).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              "You don’t have to do it perfectly to be proud of yourself 💙",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF12385C),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // HEADER
        const Text(
          "Let’s make things feel a little more doable.",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF12385C),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "You don’t have to fix everything today. We’ll pick one tiny place to start.",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF34526A),
          ),
        ),
        const SizedBox(height: 18),

        // MOOD / ENERGY CHECK-IN
        const Text(
          "How are you feeling right now?",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF12385C),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _states.map((s) {
            final selected = _selectedState == s;
            return ChoiceChip(
              label: Text(s),
              selected: selected,
              onSelected: (_) {
                HapticFeedback.lightImpact();
                setState(() => _selectedState = s);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _selectedState == null
              ? const Text(
                  "Tap one that feels closest. You’ll get a suggestion that matches your energy.",
                  key: ValueKey("noState"),
                  style: TextStyle(color: Color(0xFF34526A)),
                )
              : _GlassCard(
                  key: const ValueKey("stateCard"),
                  child: Text(
                    _stateSupport[_selectedState] ??
                        "However you’re feeling is valid. You’re not lazy or broken.",
                    style: const TextStyle(
                      color: Color(0xFF34526A),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 24),

        // BODY-DOUBLING TIMER
        const Text(
          "Body-doubling focus timer",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF12385C),
          ),
        ),
        const SizedBox(height: 8),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pick a small window where we ‘sit together’ and focus on one thing.",
                style: TextStyle(color: Color(0xFF34526A)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _presetDurations.map((m) {
                  final selected = _focusMinutes == m && !_focusActive;
                  return ChoiceChip(
                    label: Text("${m}m"),
                    selected: selected,
                    onSelected: _focusActive
                        ? null
                        : (_) => setState(() => _focusMinutes = m),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    "${_focusMinutes.toString()} min",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _focusMinutes.toDouble(),
                      min: 5,
                      max: 45,
                      divisions: 8,
                      activeColor: const Color(0xFF42A5F5),
                      inactiveColor: const Color(0xFFBBDEFB),
                      onChanged: _focusActive
                          ? null
                          : (v) => setState(() => _focusMinutes = v.round()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: _focusProgress == 0 ? null : _focusProgress,
                minHeight: 6,
                backgroundColor: const Color(0xFFE3F2FD),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF42A5F5),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _focusText,
                style: const TextStyle(color: Color(0xFF34526A)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: _focusActive ? null : _startFocusTimer,
                    child: const Text("Start"),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _focusActive ? _stopFocusTimer : null,
                    child: const Text("Stop"),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),

        // TASK BREAKDOWN
        const Text(
          "Task breakdown helper",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF12385C),
          ),
        ),
        const SizedBox(height: 8),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Type one thing that feels heavy. We’ll shrink it together.",
                style: TextStyle(color: Color(0xFF34526A)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _taskController,
                decoration: InputDecoration(
                  hintText: "Example: Finish my lab, clean my room…",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _breakTask,
                  child: const Text("Break it down"),
                ),
              ),
              if (_taskSteps.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ..._taskSteps.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      s,
                      style: const TextStyle(color: Color(0xFF34526A)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // MICRO START
        const Text(
          "Can’t start? Try one tiny move.",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF12385C),
          ),
        ),
        const SizedBox(height: 8),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "You don’t need to feel ready. Just do one tiny thing.",
                style: TextStyle(color: Color(0xFF34526A)),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _shuffleMicroAction,
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text("Give me a tiny action"),
              ),
              const SizedBox(height: 8),
              if (_currentMicroAction != null)
                Text(
                  _currentMicroAction!,
                  style: const TextStyle(
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // NOISE TOOL
        const Text(
          "Background noise to keep you company",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF12385C),
          ),
        ),
        const SizedBox(height: 8),
        _GlassCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _noiseLinks.entries.map((entry) {
              return OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(entry.key),
                onPressed: () => _openNoise(entry.key, entry.value),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // ROUTINE BUILDER
        const Text(
          "Build a tiny routine",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF12385C),
          ),
        ),
        const SizedBox(height: 8),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pick a few things. It doesn’t have to be every box.",
                style: TextStyle(color: Color(0xFF34526A)),
              ),
              CheckboxListTile(
                value: _rDrinkWater,
                onChanged: (v) => setState(() => _rDrinkWater = v ?? false),
                dense: true,
                title: const Text("Drink a glass of water"),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _rOpenPlanner,
                onChanged: (v) => setState(() => _rOpenPlanner = v ?? false),
                dense: true,
                title: const Text("Open planner / to-do app"),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _rCheckCalendar,
                onChanged: (v) => setState(() => _rCheckCalendar = v ?? false),
                dense: true,
                title: const Text("Glance at today’s calendar"),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _r10MinFocus,
                onChanged: (v) => setState(() => _r10MinFocus = v ?? false),
                dense: true,
                title: const Text("One 10-minute focus block"),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _rShortWalk,
                onChanged: (v) => setState(() => _rShortWalk = v ?? false),
                dense: true,
                title: const Text("3–5 minute stretch / walk"),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _rPackBag,
                onChanged: (v) => setState(() => _rPackBag = v ?? false),
                dense: true,
                title: const Text("Pack bag / prepare for tomorrow"),
                contentPadding: EdgeInsets.zero,
              ),
              if (_routineItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 6),
                const Text(
                  "Your tiny routine:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF12385C),
                  ),
                ),
                const SizedBox(height: 4),
                ..._routineItems.map(
                  (e) => Text(
                    "• $e",
                    style: const TextStyle(color: Color(0xFF34526A)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // TEXT YOURSELF NOTES
        const Text(
          "Quick brain-dump notes",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF12385C),
          ),
        ),
        const SizedBox(height: 8),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Drop the thought here so your brain can take a break from holding it.",
                style: TextStyle(color: Color(0xFF34526A)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: "Example: Email prof, buy shampoo, idea for later…",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _addNote,
                  child: const Text("Save note"),
                ),
              ),
              if (_notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 6),
                const Text(
                  "Saved here (local only for now):",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF12385C),
                  ),
                ),
                const SizedBox(height: 4),
                ..._notes.map(
                  (n) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      "• $n",
                      style: const TextStyle(color: Color(0xFF34526A)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// -----------------------------
// Glassmorphism card
// -----------------------------
class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFBBDEFB).withOpacity(0.9),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64B5F6).withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// -----------------------------
// Floating pixels background
// -----------------------------
class _FloatingPixels extends StatelessWidget {
  final Animation<double> animation;

  const _FloatingPixels({required this.animation});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          return Stack(
            children: [
              _pixel(
                left: 30,
                topFraction: (0.05 + t * 0.2) % 0.4,
                size: 6,
                opacity: 0.12,
              ),
              _pixel(
                right: 40,
                topFraction: (0.15 + t * 0.25) % 0.5,
                size: 8,
                opacity: 0.16,
              ),
              _pixel(
                left: 80,
                topFraction: (0.25 + t * 0.18) % 0.6,
                size: 5,
                opacity: 0.1,
              ),
              _pixel(
                right: 90,
                topFraction: (0.35 + t * 0.22) % 0.7,
                size: 7,
                opacity: 0.14,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pixel({
    double? left,
    double? right,
    required double topFraction,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: topFraction * 400,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF64B5F6),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
