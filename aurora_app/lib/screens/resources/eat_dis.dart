// eat_dis.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Aurora snackbars
import 'package:aurora_app/widgets/aurora_snackbar.dart';
import 'package:firebase_core/firebase_core.dart'; // for FirebaseException
import 'package:aurora_app/services/journal_service.dart';

class EatingDisordersHelpPage extends StatefulWidget {
  const EatingDisordersHelpPage({super.key});

  @override
  State<EatingDisordersHelpPage> createState() =>
      _EatingDisordersHelpPageState();
}

class _EatingDisordersHelpPageState extends State<EatingDisordersHelpPage> {
  // food facts cards
  final List<String> _foodFacts = [
    "Carbohydrates are your brain’s main energy source, eating them helps you think clearly and focus.",
    "Regular meals support your nervous system, making emotions feel a little more manageable.",
    "Fats help protect your organs and support hormone balance, your body needs them to function.",
    "Protein helps repair muscles, supports your immune system, and keeps you feeling steady and grounded.",
    "Micronutrients from fruits and vegetables help your brain and body recover from stress.",
    "Even small snacks can stabilize blood sugar, reducing anxiety, dizziness, and brain fog.",
  ];

  int _foodFactIndex = 0;
  Timer? _foodFactTimer;

  void _startFoodFactRotation() {
    _foodFactTimer?.cancel();
    _foodFactTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => setState(() {
        _foodFactIndex = (_foodFactIndex + 1) % _foodFacts.length;
      }),
    );
  }

  // meal timer
  double _mealTimerMinutes = 3;
  double _mealTimerTotalSeconds = 0;
  double _mealTimerRemainingSeconds = 0;
  bool _mealTimerActive = false;
  Timer? _mealTimer;

  final List<String> _mealAffirmations = [
    "You’re allowed to nourish your body — this is an act of care.",
    "Small bites still count. There is no ‘perfect’ way to eat.",
    "Your body has carried you through so much. It deserves gentle fuel.",
    "You are not alone in this moment. Many people are healing with you.",
    "Pausing for a breath is okay. You do not have to rush.",
  ];

  double get _mealTimerProgress {
    if (!_mealTimerActive || _mealTimerTotalSeconds == 0) return 0;
    final done = _mealTimerTotalSeconds - _mealTimerRemainingSeconds;
    return (done / _mealTimerTotalSeconds).clamp(0.0, 1.0);
  }

  String get _currentMealAffirmation {
    if (!_mealTimerActive) {
      return "When you’re ready, start the timer for gentle support during your meal or snack.";
    }

    final index = (_mealTimerProgress * _mealAffirmations.length)
        .floor()
        .clamp(0, _mealAffirmations.length - 1);
    return _mealAffirmations[index];
  }

  void _startMealTimer() {
    if (_mealTimerActive) return;
    _mealTimerTotalSeconds = _mealTimerMinutes * 60;
    _mealTimerRemainingSeconds = _mealTimerTotalSeconds;

    setState(() => _mealTimerActive = true);

    _mealTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _mealTimerRemainingSeconds--;
        if (_mealTimerRemainingSeconds <= 0) {
          _mealTimerActive = false;
          timer.cancel();
          showAuroraSnackBar(
            context,
            "Meal support timer finished 💙",
            variant: AuroraSnackVariant.success,
          );
        }
      });
    });
  }

  void _stopMealTimer() {
    _mealTimer?.cancel();
    setState(() {
      _mealTimerActive = false;
      _mealTimerRemainingSeconds = 0;
    });
  }

  // journal prompts
  final List<String> _journalPrompts = [
    "What is one kind thing you can say to your body today?",
    "Think of a time food felt comforting rather than scary. What was happening?",
    "What does your body need from you right now? Physically, Emotionally, or Mentally?",
    "What would you say to a friend who was struggling with food the way you are?",
    "Name three things your body lets you experience that you enjoy.",
  ];

  void _openJournalPromptSheet(String prompt) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Journal space",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF6A4C9C),
                  )),
              const SizedBox(height: 10),
              Text(prompt),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText:
                      "Write anything that comes up. This is just for you.",
                  filled: true,
                  fillColor: cs.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Close")),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) {
                        showAuroraSnackBar(
                          context,
                          "Write a few words first 💙",
                          variant: AuroraSnackVariant.info,
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      // Attempt Firestore journal save using existing JournalService path.
                      try {
                        await JournalService.instance.addEntry(
                          title: "Eating Disorders Prompt",
                          content: "Prompt: $prompt\n$text",
                          mood: "eating_disorders",
                        );
                        if (mounted) {
                          showAuroraSnackBar(
                            context,
                            "Entry saved to journal ✨",
                            variant: AuroraSnackVariant.success,
                          );
                        }
                      } on FirebaseException catch (e) {
                        // If user not signed in or other Firestore error, surface informative message.
                        showAuroraSnackBar(
                          context,
                          e.code == 'no-current-user'
                              ? "Sign in to save journal entries"
                              : "Could not save entry (${e.code})",
                          variant: AuroraSnackVariant.error,
                        );
                      } catch (_) {
                        showAuroraSnackBar(
                          context,
                          "Unexpected error saving entry",
                          variant: AuroraSnackVariant.error,
                        );
                      }
                    },
                    child: const Text("Save"),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // launch eating disorder support hotline
  Future<void> _launchEatingDisorderSupport(BuildContext context) async {
    const hotline = "+1-866-531-2600";
    final uri = Uri(scheme: "tel", path: hotline);

    try {
      if (await canLaunchUrl(uri)) {
        if (!context.mounted) return;
        await launchUrl(uri);
        if (!context.mounted) return;
        showAuroraSnackBar(
          context,
          "Dialing support…",
          variant: AuroraSnackVariant.success,
        );
        return;
      }
    } catch (_) {}

    if (!context.mounted) return;
    showAuroraSnackBar(
      context,
      "Call $hotline for support 💙",
      variant: AuroraSnackVariant.info,
    );
  }

  @override
  void initState() {
    super.initState();
    _startFoodFactRotation();
  }

  @override
  void dispose() {
    _mealTimer?.cancel();
    _foodFactTimer?.cancel();
    super.dispose();
  }

  // ui  design - pink and lavender gradient background
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "🥣  Eating Disorders",
          style: TextStyle(color: Color(0xFF4A3E6B)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF4A3E6B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE8F2),
              Color(0xFFF7E9FF),
              Color(0xFFEFE6FF),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              // food facts
              const Text(
                "Gentle food & body facts",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7B5699),
                ),
              ),
              const SizedBox(height: 12),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Container(
                  key: ValueKey(_foodFactIndex),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFCFB4F5).withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB18CE0).withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    _foodFacts[_foodFactIndex],
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF6F6580),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // meal timer
              const Text(
                "Meal support timer",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF7B5699),
                ),
              ),
              const SizedBox(height: 12),

              _buildMealTimerCard(),

              const SizedBox(height: 32),

              // journal prompts
              const Text(
                "Gentle journal prompts",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7B5699),
                ),
              ),
              const SizedBox(height: 12),

              ..._journalPrompts.map(_buildJournalTile),

              const SizedBox(height: 38),

              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD36AD8),
                ),
                onPressed: () => _launchEatingDisorderSupport(context),
                icon: const Icon(Icons.call_rounded),
                label: const Text("Talk to someone"),
              )
            ],
          ),
        ),
      ),
    );
  }

//widgets
  Widget _buildMealTimerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD5C1FA).withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCE9EEF).withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Choose how long you’d like gentle support during a meal or snack.",
            style: TextStyle(
              color: Color(0xFF6F6580),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "${_mealTimerMinutes.toStringAsFixed(0)} min",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7D5FA6),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _mealTimerMinutes,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: const Color(0xFFD36AD8),
                  inactiveColor: const Color(0xFFF5D8F5),
                  thumbColor: const Color(0xFFD36AD8),
                  onChanged: _mealTimerActive
                      ? null
                      : (v) => setState(() => _mealTimerMinutes = v),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _mealTimerProgress == 0 ? null : _mealTimerProgress,
            minHeight: 8,
            backgroundColor: const Color(0xFFFCE7F3),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFFD783F3),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _currentMealAffirmation,
            style: const TextStyle(color: Color(0xFF6F6580)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD36AD8),
                ),
                onPressed: _mealTimerActive ? null : _startMealTimer,
                child: const Text("Start"),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFFCC9EE8),
                  ),
                ),
                onPressed: _mealTimerActive ? _stopMealTimer : null,
                child: const Text("Stop"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildJournalTile(String prompt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => _openJournalPromptSheet(prompt),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFCDBDF4).withValues(alpha: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB18CE0).withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_rounded, color: Color(0xFF8D63C9)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prompt,
                  style: const TextStyle(color: Color(0xFF6F6580)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
