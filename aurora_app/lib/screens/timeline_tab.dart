import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TimelineTab extends StatelessWidget {
  final String uid;
  const TimelineTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final entriesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('journalEntries')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: entriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        // group entries by day (yyyy-MM-dd)
        final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
            grouped = {};
        for (final doc in docs) {
          final data = doc.data();
          final ts = data['createdAt'];
          DateTime date = DateTime.now();
          if (ts is Timestamp) {
            date = ts.toDate();
          }
          final key = DateFormat('yyyy-MM-dd').format(date);
          grouped.putIfAbsent(key, () => []);
          grouped[key]!.add(doc);
        }

        // newest days first
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 4),
            const _MoodCurveCard(),
            const SizedBox(height: 16),
            if (sortedKeys.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'No entries yet.\nAdd a journal entry to see your timeline here ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6F6C66),
                    height: 1.4,
                  ),
                ),
              )
            else
              for (final dayKey in sortedKeys) ...[
                _DayEntryGroup(
                  day: dayKey,
                  entries: grouped[dayKey]!,
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}

class _MoodCurveCard extends StatelessWidget {
  const _MoodCurveCard();

  @override
  Widget build(BuildContext context) {
    // Placeholder – swap with fl_chart or charts_flutter later
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7-day mood curve',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F2E2C),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF5EFE7),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Chart placeholder\n(tap to filter by day)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF6F6C66)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap any point to see entries from that day',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF6F6C66),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayEntryGroup extends StatelessWidget {
  final String day;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> entries;
  const _DayEntryGroup({
    required this.day,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(day);
    final label = DateFormat('MMM d').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6F6C66),
          ),
        ),
        const SizedBox(height: 8),
        for (final doc in entries)
          _TimelineEntryTile(
            title: (doc.data()['title'] ?? '') as String,
            mood: (doc.data()['mood'] ?? 'neutral') as String,
          ),
      ],
    );
  }
}

class _TimelineEntryTile extends StatelessWidget {
  final String title;
  final String mood;
  const _TimelineEntryTile({
    required this.title,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    String emoji = '😊';
    switch (mood) {
      case 'sad':
        emoji = '😢';
        break;
      case 'overwhelmed':
        emoji = '😵';
        break;
      case 'calm':
        emoji = '😌';
        break;
      case 'neutral':
        emoji = '😐';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE4D7CB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.calendar_today_rounded,
            color: Color(0xFF2F2E2C),
            size: 18,
          ),
        ),
        title: Text(
          title.isEmpty ? 'Untitled entry' : title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2F2E2C),
          ),
        ),
        trailing: Text(
          emoji,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
