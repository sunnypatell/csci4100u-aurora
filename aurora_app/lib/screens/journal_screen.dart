import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/journal_service.dart';
import '../widgets/auth/custom_text_field.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedMood = 'neutral';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something first 🙂')),
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
      _titleController.clear();
      _contentController.clear();
      setState(() => _selectedMood = 'neutral');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal entry saved! 📝')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving entry: $e')),
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
        title: const Text(
          'Journal',
          style: TextStyle(color: Color(0xFF2F2E2C)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2F2E2C)),
      ),
      body: user == null
          ? const Center(child: Text('Please sign in to view your journal'))
          : Column(
              children: [
                // input card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _titleController,
                          label: 'Title',
                          hintText: 'Grateful for today...',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Mood',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6F6C66),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedMood,
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
                          items: const [
                            DropdownMenuItem(
                              value: 'neutral',
                              child: Text('Neutral'),
                            ),
                            DropdownMenuItem(
                              value: 'happy',
                              child: Text('Happy'),
                            ),
                            DropdownMenuItem(
                              value: 'sad',
                              child: Text('Sad'),
                            ),
                            DropdownMenuItem(
                              value: 'anxious',
                              child: Text('Anxious'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedMood = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _contentController,
                          label: 'Entry',
                          hintText: 'Write about your day, thoughts, feelings...',
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
                                        fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
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
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: JournalService.instance.journalEntriesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
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
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final title = (data['title'] ?? '') as String;
                          final content = (data['content'] ?? '') as String;
                          final mood = (data['mood'] ?? 'neutral') as String;
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade300,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title.isEmpty ? 'Untitled entry' : title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2F2E2C),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5EFE7),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          mood,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF2F2E2C),
                                          ),
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
                                  ),
                                  if (created != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '${created.toLocal()}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9C9A96),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}