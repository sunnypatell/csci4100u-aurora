import 'package:flutter/material.dart';
/// JournalScreen
/// Provides a multi-tab journaling interface: compose entries with mood tags,
/// search/filter existing entries, and visualize mood trends (timeline tab).
/// Entries are stored per-user in Firestore via JournalService. UX focuses on
/// low friction: minimal required fields, emoji mood quick picks, and date
/// formatting helpers for human-friendly “Today / Yesterday” labels.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/journal_service.dart';
import '../widgets/auth/custom_text_field.dart';
import '../widgets/aurora_snackbar.dart';
import '../services/notifications_service.dart';
import 'timeline_tab.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedMood = 'neutral';
  bool _isSaving = false;

  // Filter state for entries list
  String _filterMood = 'all'; // mood filter: 'all' or specific mood
  String _entryDateFilter = 'all'; // 'all', '7', '30' (days)

  int _currentTab = 0;

  // Primary moods used in the quick picker row
  static const List<String> _primaryMoods = [
    'happy',
    'sad',
    'anxious',
    'angry',
    'excited',
    'calm',
    'tired',
    'grateful',
    'neutral',
  ];

  // Moods -> emoji for display
  static const Map<String, String> _moodEmoji = {
    'happy': '😊',
    'sad': '😢',
    'anxious': '😰',
    'angry': '😠',
    'excited': '🤩',
    'calm': '😌',
    'tired': '🥱',
    'grateful': '🙏',
    'neutral': '😐',
    // Resource-origin moods (added so dropdown editing does not assert)
    'eating_disorders': '🥣',
    'adhd_focus': '🧠',
    'adhd_note': '📝',
    'anxiety_depression': '💙',
  };

  // Gentle mood-specific prompts to surface as quick actions
  static const Map<String, List<String>> _moodPrompts = {
    'happy': [
      'What made today feel good?',
      'Who or what are you grateful for right now?',
    ],
    'sad': [
      'What feels heavy for you today?',
      'What’s one small comfort you can offer yourself?',
    ],
    'anxious': [
      'What are you most worried about in this moment?',
      'What is one thing you can actually control right now?',
    ],
    'angry': [
      'What crossed a boundary for you today?',
      'What would you like to say, even if just here?',
    ],
    'excited': [
      'What are you looking forward to?',
      'What gave you a spark of energy today?',
    ],
    'calm': [
      'When today did you feel most at ease?',
      'What helped you feel grounded?',
    ],
    'tired': [
      'What drained your energy today?',
      'What would true rest look like for you?',
    ],
    'grateful': [
      'List three small things you’re glad about today.',
      'Who showed up for you recently?',
    ],
    'neutral': [
      'What stood out about today, even if it felt ordinary?',
      'How did your body feel through the day?',
    ],
    'default': [
      'What stood out about today?',
      'How are you feeling right now, in your own words?',
    ],
  };

  /// Maps mood key to a gentle background color.
  Color _moodColor(String mood) {
    switch (mood) {
      case 'happy':
      case 'excited':
      case 'grateful':
        return const Color(0xFFFDE4C5); // warm peach
      case 'sad':
        return const Color(0xFFE3ECFF); // soft blue
      case 'anxious':
        return const Color(0xFFE6F2F0); // mint/teal
      case 'angry':
        return const Color(0xFFF9D2D2); // soft red
      case 'calm':
        return const Color(0xFFE4F1F5); // gentle teal
      case 'tired':
        return const Color(0xFFE9E2F2); // muted purple
      case 'neutral':
      default:
        return const Color(0xFFF5EFE7); // neutral beige used in theme
    }
  }

  // Static helper so stateless widgets can access mood colors.
  static Color _moodColorStatic(String mood) {
    // Safe because this method doesn't depend on any instance state.
    return _JournalScreenState()._moodColor(mood);
  }

  /// Produces a friendly timestamp (Today / Yesterday / explicit date).
  String _formatWhen(DateTime when) {
    final now = DateTime.now();
    final local = when.toLocal();
    final isSameDay =
        now.year == local.year && now.month == local.month && now.day == local.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == local.year &&
        yesterday.month == local.month &&
        yesterday.day == local.day;

    if (isSameDay) {
      return 'Today • ${DateFormat('h:mm a').format(local)}';
    } else if (isYesterday) {
      return 'Yesterday • ${DateFormat('h:mm a').format(local)}';
    }
    return DateFormat('MMM d, y • h:mm a').format(local);
  }

  // Reusable mood item widget for dropdowns (emoji + label)
  static Widget _moodItem(String emoji, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Persists a new journal entry after basic emptiness check. Resets fields
  /// & mood selection on success, surfacing status via snackbar.
  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      showAuroraSnackBar(
        context,
        'Write something first 🙂',
        variant: AuroraSnackVariant.info,
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await JournalService.instance.addEntry(
        title: _titleController.text,
        content: _contentController.text,
        mood: _selectedMood,
      );
      if (!mounted) return;
      _titleController.clear();
      _contentController.clear();
      setState(() => _selectedMood = 'neutral');
      showAuroraSnackBar(
        context,
        'Journal entry saved! 📝',
        variant: AuroraSnackVariant.success,
      );
      // Ensure a daily reminder exists; non-forced call avoids duplication.
      await NotificationService.instance.scheduleDailyJournalReminder();
    } catch (e) {
      if (!mounted) return;
      showAuroraSnackBar(
        context,
        'Error saving entry: $e',
        variant: AuroraSnackVariant.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EFE7),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Journal',
          style: TextStyle(color: Color(0xFF2F2E2C)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2F2E2C)),
      ),
      resizeToAvoidBottomInset: true,
      body: user == null
          ? const Center(child: Text('Please sign in to view your journal'))
          : Column(
              children: [
                const SizedBox(height: 8),
                _buildTabSwitcher(),
                const SizedBox(height: 8),
                Expanded(
                  child: _currentTab == 0
                      ? _buildEntriesContent(context)
                      : TimelineTab(uid: user.uid),
                ),
              ],
            ),
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            _TabChip(
              text: 'Entries',
              selected: _currentTab == 0,
              onTap: () => setState(() => _currentTab = 0),
            ),
            _TabChip(
              text: 'Timeline',
              selected: _currentTab == 1,
              onTap: () => setState(() => _currentTab = 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesContent(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          children: [
            // Input card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      _moodColor(_selectedMood).withValues(alpha: 0.40),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      controller: _titleController,
                      label: 'Title',
                      hintText: 'Grateful for today...',
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mood',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6F6C66),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MoodChipRow(
                      selectedMood: _selectedMood,
                      onChanged: (mood) {
                        setState(() => _selectedMood = mood);
                      },
                    ),
                    const SizedBox(height: 8),
                    _PromptRow(
                      mood: _selectedMood,
                      onTapPrompt: (prompt) {
                        final current = _contentController.text;
                        if (current.trim().isEmpty) {
                          _contentController.text = prompt;
                        } else {
                          final needsSpace =
                              !current.endsWith(' ') && !current.endsWith('\n');
                          _contentController.text =
                              "$current${needsSpace ? ' ' : ''}$prompt";
                        }
                        _contentController.selection =
                            TextSelection.fromPosition(
                          TextPosition(offset: _contentController.text.length),
                        );
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _contentController,
                      label: 'Entry',
                      hintText: 'Write about your day, thoughts, feelings...',
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 5,
                      maxLines: 12,
                      validator: null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF2B8A0),
                          foregroundColor: const Color(0xFF2F2E2C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Color(0xFF2F2E2C),
                                  ),
                                ),
                              )
                            : const Text(
                                'Save entry',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your entries',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2F2E2C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Search and filter row
                  Row(
                    children: [
                      // Search by title
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search by title…',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Mood filter dropdown
                      DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFFE8E4DC)),
                          ),
                          child: DropdownButton<String>(
                            value: _filterMood,
                            items: [
                              DropdownMenuItem(
                                value: 'all',
                                child: _moodItem('🌐', 'All'),
                              ),
                              DropdownMenuItem(
                                value: 'happy',
                                child: _moodItem('😊', 'Happy'),
                              ),
                              DropdownMenuItem(
                                value: 'sad',
                                child: _moodItem('😢', 'Sad'),
                              ),
                              DropdownMenuItem(
                                value: 'anxious',
                                child: _moodItem('😰', 'Anxious'),
                              ),
                              DropdownMenuItem(
                                value: 'angry',
                                child: _moodItem('😠', 'Angry'),
                              ),
                              DropdownMenuItem(
                                value: 'excited',
                                child: _moodItem('🤩', 'Excited'),
                              ),
                              DropdownMenuItem(
                                value: 'calm',
                                child: _moodItem('😌', 'Calm'),
                              ),
                              DropdownMenuItem(
                                value: 'tired',
                                child: _moodItem('🥱', 'Tired'),
                              ),
                              DropdownMenuItem(
                                value: 'grateful',
                                child: _moodItem('🙏', 'Grateful'),
                              ),
                              DropdownMenuItem(
                                value: 'neutral',
                                child: _moodItem('😐', 'Neutral'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _filterMood = v ?? 'all'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Mood + Date Range Filters
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // --- Mood Filter Pills ---
                        _FilterChipPill(
                          label: 'All moods',
                          selected: _filterMood == 'all',
                          onTap: () => setState(() => _filterMood = 'all'),
                        ),
                        _FilterChipPill(
                          label: 'Happy',
                          selected: _filterMood == 'happy',
                          onTap: () => setState(() => _filterMood = 'happy'),
                        ),
                        _FilterChipPill(
                          label: 'Sad',
                          selected: _filterMood == 'sad',
                          onTap: () => setState(() => _filterMood = 'sad'),
                        ),
                        _FilterChipPill(
                          label: 'Anxious',
                          selected: _filterMood == 'anxious',
                          onTap: () =>
                              setState(() => _filterMood = 'anxious'),
                        ),
                        _FilterChipPill(
                          label: 'Angry',
                          selected: _filterMood == 'angry',
                          onTap: () => setState(() => _filterMood = 'angry'),
                        ),
                        _FilterChipPill(
                          label: 'Calm',
                          selected: _filterMood == 'calm',
                          onTap: () => setState(() => _filterMood = 'calm'),
                        ),
                        _FilterChipPill(
                          label: 'Tired',
                          selected: _filterMood == 'tired',
                          onTap: () => setState(() => _filterMood = 'tired'),
                        ),
                        _FilterChipPill(
                          label: 'Grateful',
                          selected: _filterMood == 'grateful',
                          onTap: () =>
                              setState(() => _filterMood = 'grateful'),
                        ),
                        _FilterChipPill(
                          label: 'Neutral',
                          selected: _filterMood == 'neutral',
                          onTap: () => setState(() => _filterMood = 'neutral'),
                        ),

                        // --- Date Range Filters ---
                        _FilterChipPill(
                          label: 'All time',
                          selected: _entryDateFilter == 'all',
                          onTap: () =>
                              setState(() => _entryDateFilter = 'all'),
                        ),
                        _FilterChipPill(
                          label: 'Last 7 days',
                          selected: _entryDateFilter == '7',
                          onTap: () =>
                              setState(() => _entryDateFilter = '7'),
                        ),
                        _FilterChipPill(
                          label: 'Last 30 days',
                          selected: _entryDateFilter == '30',
                          onTap: () =>
                              setState(() => _entryDateFilter = '30'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: JournalService.instance.journalEntriesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(
                            top: 24.0,
                            bottom: 40.0,
                          ),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                          snapshot.data?.docs ?? [];

                      // Client-side filtering: mood, date range, title search
                      final q =
                          _searchController.text.trim().toLowerCase();

                      if (_filterMood != 'all') {
                        docs = docs
                            .where((d) =>
                                (d.data()['mood'] ?? 'neutral') ==
                                _filterMood)
                            .toList();
                      }

                      if (_entryDateFilter != 'all') {
                        final now = DateTime.now();
                        final limitDays =
                            _entryDateFilter == '7' ? 7 : 30;
                        docs = docs.where((d) {
                          final data = d.data();
                          final ts = data['createdAt'];
                          if (ts is! Timestamp) return false;
                          final dt = ts.toDate();
                          return now.difference(dt).inDays < limitDays;
                        }).toList();
                      }

                      if (q.isNotEmpty) {
                        docs = docs.where((d) {
                          final title = (d.data()['title'] ?? '')
                              .toString()
                              .toLowerCase();
                          return title.contains(q);
                        }).toList();
                      }

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No entries yet. Start by writing one above 👆',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final title = (data['title'] ?? '') as String;
                          final content =
                              (data['content'] ?? '') as String;
                          final mood =
                              (data['mood'] ?? 'neutral') as String;
                          final ts = data['createdAt'];
                          DateTime? created;
                          if (ts is Timestamp) {
                            created = ts.toDate();
                          }

                          return Dismissible(
                            key: ValueKey(doc.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) {
                              JournalService.instance.deleteEntry(doc.id);
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade300,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showEditEntrySheet(
                                entryId: doc.id,
                                initialTitle: title,
                                initialContent: content,
                                initialMood: mood,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      _moodColor(mood)
                                          .withValues(alpha: 0.60),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title.isEmpty
                                                ? 'Untitled entry'
                                                : title,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2F2E2C),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _moodColor(mood),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              Text(
                                                _moodEmoji[mood] ?? '🙂',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                mood,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Color(0xFF2F2E2C),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      content,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF6F6C66),
                                      ),
                                      maxLines: 6,
                                      overflow: TextOverflow.fade,
                                    ),
                                    if (created != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatWhen(created),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF9C9A96),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditEntrySheet({
    required String entryId,
    required String initialTitle,
    required String initialContent,
    required String initialMood,
  }) async {
    final titleCtrl = TextEditingController(text: initialTitle);
    final contentCtrl = TextEditingController(text: initialContent);
    String mood = initialMood;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit entry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F2E2C),
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: titleCtrl,
                label: 'Title',
                hintText: 'Untitled entry',
              ),
              const SizedBox(height: 12),
              const Text(
                'Mood',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6F6C66),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: mood,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5EFE7),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFF2B8A0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFF2B8A0),
                      width: 2,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'neutral',
                    child: _moodItem('😐', 'Neutral'),
                  ),
                  DropdownMenuItem(
                    value: 'happy',
                    child: _moodItem('😊', 'Happy'),
                  ),
                  DropdownMenuItem(
                    value: 'sad',
                    child: _moodItem('😢', 'Sad'),
                  ),
                  DropdownMenuItem(
                    value: 'anxious',
                    child: _moodItem('😰', 'Anxious'),
                  ),
                  DropdownMenuItem(
                    value: 'angry',
                    child: _moodItem('😠', 'Angry'),
                  ),
                  DropdownMenuItem(
                    value: 'excited',
                    child: _moodItem('🤩', 'Excited'),
                  ),
                  DropdownMenuItem(
                    value: 'calm',
                    child: _moodItem('😌', 'Calm'),
                  ),
                  DropdownMenuItem(
                    value: 'tired',
                    child: _moodItem('🥱', 'Tired'),
                  ),
                  DropdownMenuItem(
                    value: 'grateful',
                    child: _moodItem('🙏', 'Grateful'),
                  ),
                  if (_moodEmoji.containsKey(mood) &&
                      ![
                        'neutral',
                        'happy',
                        'sad',
                        'anxious',
                        'angry',
                        'excited',
                        'calm',
                        'tired',
                        'grateful',
                      ].contains(mood))
                    DropdownMenuItem(
                      value: mood,
                      child: _moodItem(
                        _moodEmoji[mood] ?? '📝',
                        mood.replaceAll('_', ' '),
                      ),
                    ),
                ],
                onChanged: (val) => mood = val ?? 'neutral',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: contentCtrl,
                label: 'Entry',
                hintText: 'Update your thoughts...',
                keyboardType: TextInputType.multiline,
                minLines: 5,
                maxLines: 12,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2B8A0),
                    foregroundColor: const Color(0xFF2F2E2C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (Navigator.canPop(ctx)) {
                      Navigator.of(ctx).pop();
                    }
                    await JournalService.instance.updateEntry(
                      entryId,
                      title: titleCtrl.text,
                      content: contentCtrl.text,
                      mood: mood,
                    );
                  },
                  child: const Text(
                    'Save changes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF2B8A0) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: const Color(0xFF2F2E2C),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal row of animated mood chips used for quick selection.
class _MoodChipRow extends StatelessWidget {
  final String selectedMood;
  final ValueChanged<String> onChanged;

  const _MoodChipRow({
    required this.selectedMood,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final mood in _JournalScreenState._primaryMoods)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _MoodChip(
                mood: mood,
                selected: selectedMood == mood,
                onTap: () => onChanged(mood),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  final String mood;
  final bool selected;
  final VoidCallback onTap;

  const _MoodChip({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = _JournalScreenState._moodEmoji[mood] ?? '🙂';
    final displayLabel = mood.replaceAll('_', ' ');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? _JournalScreenState._moodColorStatic(mood)
                  .withValues(alpha: 0.4)
              : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? _JournalScreenState._moodColorStatic(mood)
                : const Color(0xFFE0D7CC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: const Color(0xFF2F2E2C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a few quick prompts that insert text into the entry when tapped.
class _PromptRow extends StatelessWidget {
  final String mood;
  final ValueChanged<String> onTapPrompt;

  const _PromptRow({
    required this.mood,
    required this.onTapPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final prompts = _JournalScreenState._moodPrompts[mood] ??
        _JournalScreenState._moodPrompts['default'] ??
        const <String>[];

    if (prompts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Need inspiration?',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6F6C66),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final p in prompts.take(3))
              ActionChip(
                label: Text(
                  p,
                  style: const TextStyle(fontSize: 11),
                ),
                onPressed: () => onTapPrompt(p),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: const BorderSide(color: Color(0xFFE0D7CC)),
                ),
              ),
            // A micro-journal “one sentence check-in”
            ActionChip(
              label: const Text(
                'One-sentence check-in',
                style: TextStyle(fontSize: 11),
              ),
              onPressed: () => onTapPrompt('Today I feel because...'),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: const BorderSide(color: Color(0xFFE0D7CC)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF2B8A0).withValues(alpha: 0.4)
              : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFFF2B8A0)
                : const Color(0xFFE0D7CC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: const Color(0xFF2F2E2C),
          ),
        ),
      ),
    );
  }
}
