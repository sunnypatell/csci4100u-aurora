import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

// Aurora snackbars
import 'package:aurora_app/widgets/aurora_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnxietyDepressionHelpPage extends StatefulWidget {
  const AnxietyDepressionHelpPage({super.key});

  @override
  State<AnxietyDepressionHelpPage> createState() =>
      _AnxietyDepressionHelpPageState();
}

class _AnxietyDepressionHelpPageState extends State<AnxietyDepressionHelpPage>
    with TickerProviderStateMixin {
  // breathing pup
  late final AnimationController _dogBreathCtrl;
  late final Animation<double> _dogScale;

// wheel of emotions
  final List<String> _emotions = [
    "anxious",
    "restless",
    "sad",
    "numb",
    "overwhelmed",
    "stressed",
    "lonely",
    "hopeless",
  ];

  final Map<String, String> _emotionSupport = {
    "anxious":
        "Anxiety is your brain trying to protect you. We’ll slow it down together, one breath at a time.",
    "restless":
        "Your body wants to move. A tiny walk, stretch or fidget is allowed.",
    "sad": "Sadness is heavy. You don’t have to explain it to deserve comfort.",
    "numb":
        "Feeling nothing is still a feeling. You’re not broken for going quiet inside.",
    "overwhelmed":
        "You don’t have to sort everything today. We’ll pick one small corner to care for.",
    "stressed":
        "Your nervous system is working overtime. Food, water and breath are not ‘extra’, they’re support.",
    "lonely":
        "Being lonely doesn’t mean you are unlovable. You matter more than your brain says right now.",
    "hopeless":
        "Hopelessness is a feeling, not a prediction. You’ve survived every hard day so far.",
  };

  String _currentEmotion = "anxious";
  bool _emotionSpinning = false;
  Timer? _emotionTimer;

// 5-4-3-2-1 grounding
  final PageController _groundingController = PageController();
  final List<String> _groundingSteps = [
    "5 things you can SEE.\nLook for colours, shapes, light.",
    "4 things you can TOUCH.\nNotice temperature, texture, pressure.",
    "3 things you can HEAR.\nNear, far, steady, or tiny sounds.",
    "2 things you can SMELL.\nOr imagine a comforting smell.",
    "1 thing you can TASTE.\nEven imagining a favourite snack counts.",
  ];

// sound mood buttons
  final Map<String, String> _soundLinks = {
    "Rain on window":
        "https://www.youtube.com/results?search_query=rain+sounds",
    "Ocean waves":
        "https://www.youtube.com/results?search_query=ocean+waves+relax",
    "Brown noise": "https://www.youtube.com/results?search_query=brown+noise",
    "Soft piano":
        "https://www.youtube.com/results?search_query=soft+piano+sleep",
    "Night library":
        "https://www.youtube.com/results?search_query=library+ambience",
  };

  // self-harm safe alternatives spinner
  final List<String> _copingIdeas = [
    "Hold an ice cube and notice the sharp, cold sensation.",
    "Draw on your arm with a marker where you feel the urge.",
    "Wrap yourself in a blanket and squeeze a pillow tight.",
    "Run your hands under cold or warm water and describe the feeling.",
    "Do 10 slow shoulder rolls and unclench your jaw.",
    "Write the urge down in a note and rate it 0–10.",
    "Squeeze a stress ball or soft object until your hands are tired.",
    "Text or message someone safe, even if it’s just an emoji.",
  ];

  String? _currentCoping;
  bool _copingSpinning = false;
  Timer? _copingTimer;

  // urge wave slider (0–10)
  double _urgeLevel = 0;

  String get _urgeText {
    if (_urgeLevel == 0) {
      return "No urge right now is still worth noticing. This calm is real too.";
    } else if (_urgeLevel <= 3) {
      return "Mild urge. Try one tiny coping idea now before it grows.";
    } else if (_urgeLevel <= 6) {
      return "Medium wave. Urges rise and fall like a graph – you don’t have to act on it.";
    } else if (_urgeLevel <= 8) {
      return "Strong wave. Please use your safest skills and consider reaching out.";
    }
    return "Very strong wave. You deserve live support – crisis lines and trusted people can hold this with you.";
  }

  // resons to stay text list
  final TextEditingController _reasonController = TextEditingController();

  CollectionReference<Map<String, dynamic>>? get _reasonsCol {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('reasonsToStay');
  }

  Future<void> _addReason() async {
    final text = _reasonController.text.trim();
    if (text.isEmpty) {
      showAuroraSnackBar(
        context,
        "Write one small reason – it can be silly or tiny.",
        variant: AuroraSnackVariant.info,
      );
      return;
    }
    _reasonController.clear();
    final col = _reasonsCol;
    if (col == null) {
      showAuroraSnackBar(
        context,
        'Sign in to save reasons',
        variant: AuroraSnackVariant.error,
      );
      return;
    }
    try {
      await col.add({
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      if (mounted) {
        showAuroraSnackBar(
          context,
          'Reason saved ✨',
          variant: AuroraSnackVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAuroraSnackBar(
          context,
          'Failed to save reason',
          variant: AuroraSnackVariant.error,
        );
      }
    }
  }

  Future<void> _deleteReason(String docId) async {
    final col = _reasonsCol;
    if (col == null) return;
    try {
      await col.doc(docId).delete();
      if (!mounted) return;
      if (mounted) {
        showAuroraSnackBar(
          context,
          'Reason removed',
          variant: AuroraSnackVariant.info,
        );
      }
    } catch (_) {
      if (mounted) {
        showAuroraSnackBar(
          context,
          'Could not delete reason',
          variant: AuroraSnackVariant.error,
        );
      }
    }
  }

  // quick reset card
  final List<Map<String, String>> _resetCards = [
    {
      "title": "30-second body scan",
      "text":
          "Notice forehead • jaw • shoulders • hands • legs • feet. Soften one place by 5%. That’s enough."
    },
    {
      "title": "Colour hunt",
      "text":
          "Pick a colour (blue, green, pink). Find 5 things around you in that colour. Say them out loud."
    },
    {
      "title": "Name it game",
      "text":
          "Say: “I am feeling ___ and that makes sense because ___.” No judgment, just describing."
    },
    {
      "title": "Future you check-in",
      "text":
          "Ask: “What would future-me be grateful I did in the next 5 minutes?” Do just that tiny thing."
    },
  ];
  int _resetIndex = 0;
  bool _resetFlipped = false;

  void _nextResetCard() {
    setState(() {
      _resetFlipped = !_resetFlipped;
      _resetIndex = (_resetIndex + 1) % _resetCards.length;
    });
  }

  @override
  void initState() {
    super.initState();

    _dogBreathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _dogScale = Tween<double>(begin: 0.9, end: 1.05)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_dogBreathCtrl);
  }

  @override
  void dispose() {
    _dogBreathCtrl.dispose();
    _emotionTimer?.cancel();
    _copingTimer?.cancel();
    _groundingController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // helpers
  void _spinEmotionWheel() {
    if (_emotionSpinning) return;
    _emotionSpinning = true;

    final rand = Random();
    int ticks = 0;
    _emotionTimer?.cancel();
    _emotionTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      setState(() {
        _currentEmotion = _emotions[rand.nextInt(_emotions.length)];
      });
      ticks++;
      if (ticks > 12) {
        timer.cancel();
        _emotionSpinning = false;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _spinCopingIdea() {
    if (_copingSpinning) return;
    _copingSpinning = true;

    final rand = Random();
    int ticks = 0;
    _copingTimer?.cancel();
    _copingTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      setState(() {
        _currentCoping = _copingIdeas[rand.nextInt(_copingIdeas.length)];
      });
      ticks++;
      if (ticks > 14) {
        timer.cancel();
        _copingSpinning = false;
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _openSound(String label, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        showAuroraSnackBar(
          context,
          "Opening $label…",
          variant: AuroraSnackVariant.success,
        );
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    showAuroraSnackBar(
      context,
      "Couldn’t open $label. You can search it manually too.",
      variant: AuroraSnackVariant.alert,
    );
  }

  Future<void> _launchSupport(BuildContext context) async {
    const campusUrl =
        'https://studentservices.ontariotechu.ca/current-students/health-and-wellness/i-am-in-distress/index.php';
    const hotlineNumber = '+1-866-531-2600';
    final hotlineUri = Uri(scheme: 'tel', path: hotlineNumber);

    try {
      final campusUri = Uri.parse(campusUrl);
      if (await canLaunchUrl(campusUri)) {
        await launchUrl(campusUri, mode: LaunchMode.externalApplication);
        if (!context.mounted) return;
        showAuroraSnackBar(
          context,
          'Opening campus wellness resources…',
          variant: AuroraSnackVariant.success,
        );
        return;
      }
    } catch (_) {}
    try {
      if (await canLaunchUrl(hotlineUri)) {
        await launchUrl(hotlineUri);
        if (!context.mounted) return;
        showAuroraSnackBar(
          context,
          'Dialing mental health support…',
          variant: AuroraSnackVariant.success,
          icon: Icons.call_rounded,
        );
        return;
      }
    } catch (_) {}
    if (!context.mounted) return;
    showAuroraSnackBar(
      context,
      'Call $hotlineNumber for mental health support',
      variant: AuroraSnackVariant.info,
      icon: Icons.call_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "🌊  Anxiety & Depression",
          style: TextStyle(color: Color(0xFF16324F)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF16324F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFE8EAF6),
              Color(0xFFE0F2F1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // dog + header
              Center(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _dogScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _dogScale.value,
                          child: child,
                        );
                      },
                      child: const _BreathingDogFace(),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Breathe with your pup.",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF16324F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Inhale as their cheeks puff • Hold • Exhale as they soften.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF455A64),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // emotion spin wheel
              const Text(
                "How are you feeling (roughly)?",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 8),
              _GlassCard(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _spinEmotionWheel,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF90CAF9),
                              Color(0xFFB39DDB),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF64B5F6).withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentEmotion.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Tap to spin. There’s no wrong answer, just a rough vibe check.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF455A64),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _emotionSupport[_currentEmotion] ??
                          "Whatever you’re feeling, it makes sense. You’re allowed to be gentle with yourself.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // grounding carousel
              const Text(
                "5-4-3-2-1 grounding (swipe)",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: PageView.builder(
                  controller: _groundingController,
                  itemCount: _groundingSteps.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _GlassCard(
                        child: Text(
                          _groundingSteps[index],
                          style: const TextStyle(
                            color: Color(0xFF263238),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // sound mood buttons
              const Text(
                "Background sounds to sit with you",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 8),
              _GlassCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _soundLinks.entries.map((e) {
                    return OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(e.key),
                      onPressed: () => _openSound(e.key, e.value),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // urge wave & coping spinner
              const Text(
                "Riding the wave of big feelings",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 8),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "If you’re having self-harm thoughts or really heavy urges, this is a non-judgment space.",
                      style: TextStyle(color: Color(0xFF455A64)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "How strong is the urge right now?",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF16324F),
                      ),
                    ),
                    Slider(
                      value: _urgeLevel,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: _urgeLevel.round().toString(),
                      activeColor: const Color(0xFFEF9A9A),
                      inactiveColor: const Color(0xFFFFCDD2),
                      onChanged: (v) {
                        setState(() => _urgeLevel = v);
                      },
                    ),
                    Text(
                      _urgeText,
                      style: const TextStyle(color: Color(0xFF263238)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Spin a gentler alternative:",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF16324F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _spinCopingIdea,
                      icon: const Icon(Icons.autorenew_rounded),
                      label: const Text("Give me a coping idea"),
                    ),
                    const SizedBox(height: 10),
                    if (_currentCoping != null)
                      Text(
                        _currentCoping!,
                        style: const TextStyle(
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // reasons to stay text list
              const Text(
                "Tiny reasons to stay",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 8),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "These don’t have to be deep or profound. “Bubble tea” counts. “My dog” counts.",
                      style: TextStyle(color: Color(0xFF455A64)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _reasonController,
                      decoration: InputDecoration(
                        hintText: "Add one tiny reason…",
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _addReason,
                        child: const Text("Save"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _reasonsCol
                          ?.orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (_reasonsCol == null) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Sign in to save your reasons.',
                              style: TextStyle(color: Color(0xFF5D4037)),
                            ),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'No reasons yet. Add one above.',
                              style: TextStyle(color: Color(0xFF5D4037)),
                            ),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final d in docs)
                              GestureDetector(
                                onLongPress: () => _deleteReason(d.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF9C4),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          (d.data()['text'] ?? '') as String,
                                          style: const TextStyle(
                                            color: Color(0xFF5D4037),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _deleteReason(d.id),
                                        borderRadius: BorderRadius.circular(999),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: Color(0xFF5D4037),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // quick reset card
              const Text(
                "Need a quick 30-second reset?",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _nextResetCard,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    final rotate =
                        Tween(begin: pi, end: 0.0).animate(animation);
                    return AnimatedBuilder(
                      animation: rotate,
                      child: child,
                      builder: (context, child) {
                        final value = rotate.value;
                        return Transform(
                          transform: Matrix4.rotationY(value),
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                    );
                  },
                  child: _GlassCard(
                    key: ValueKey(_resetIndex),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _resetCards[_resetIndex]["title"]!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16324F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _resetCards[_resetIndex]["text"]!,
                          style: const TextStyle(color: Color(0xFF263238)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Tap card for another idea.",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF607D8B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // support button
              FilledButton.icon(
                onPressed: () => _launchSupport(context),
                icon: const Icon(Icons.call_rounded),
                label: const Text("Talk to someone"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// dog face widget
class _BreathingDogFace extends StatelessWidget {
  const _BreathingDogFace();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF3E0),
            Color(0xFFFFE0B2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB74D).withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ears
          Positioned(
            top: 20,
            left: 28,
            child: _ear(),
          ),
          Positioned(
            top: 20,
            right: 28,
            child: _ear(),
          ),
          // face
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFE0B2),
                width: 3,
              ),
            ),
          ),
          // muzzle
          Positioned(
            bottom: 30,
            child: Container(
              width: 70,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          // eyes
            const Positioned(
              top: 55,
              left: 46,
              child: _Eye(),
            ),
            const Positioned(
              top: 55,
              right: 46,
              child: _Eye(),
            ),
          // nose
          Positioned(
            bottom: 44,
            child: Container(
              width: 12,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF5D4037),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // mouth
          Positioned(
            bottom: 32,
            child: Container(
              width: 26,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFF5D4037), width: 2),
                ),
              ),
            ),
          ),
          // cheeks
          Positioned(
            bottom: 40,
            left: 38,
            child: _cheek(),
          ),
          Positioned(
            bottom: 40,
            right: 38,
            child: _cheek(),
          ),
        ],
      ),
    );
  }

  Widget _ear() {
    return Container(
      width: 24,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0B2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _cheek() {
    return Container(
      width: 14,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFFFCDD2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

  class _Eye extends StatelessWidget {
    const _Eye();
  
    @override
    Widget build(BuildContext context) {
      return Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFF263238),
          shape: BoxShape.circle,
        ),
      );
    }
  }

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFBBDEFB).withValues(alpha: 0.9),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64B5F6).withValues(alpha: 0.2),
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
