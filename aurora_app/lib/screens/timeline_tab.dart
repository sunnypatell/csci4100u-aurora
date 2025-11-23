// TimelineTab
// Visual + chronological representation of recent journal activity.
// Top section: summary mood trend (last 7 days averaged) rendered with a
// smooth line chart. Below: date-grouped entries newest-first.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class TimelineTab extends StatefulWidget {
  final String uid;
  const TimelineTab({super.key, required this.uid});

  @override
  State<TimelineTab> createState() => _TimelineTabState();
}

enum _MoodRange { seven, thirty }

class _TimelineTabState extends State<TimelineTab> {
  _MoodRange _range = _MoodRange.seven;

  // mood → numeric score
  static const Map<String, double> _moodScore = {
    'excited': 5,
    'happy': 4,
    'grateful': 4,
    'calm': 3,
    'neutral': 2,
    'tired': 2,
    'anxious': 1,
    'sad': 1,
    'angry': 1,
  };

  @override
  Widget build(BuildContext context) {
    final entriesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
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

        // 1) group by date for the list
        final Map<String,
            List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped = {};
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
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // newest first

        // 2) build 7-day mood data for the chart
        final moodData = _buildMoodData(docs, _range == _MoodRange.seven ? 7 : 30);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 4),
            _MoodChartCard(
              moodData: moodData,
              days: _range == _MoodRange.seven ? 7 : 30,
              onSelectRange: _showRangeDialog,
            ),
            const SizedBox(height: 16),
            if (sortedKeys.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'No entries yet. Add a journal entry to see your timeline here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6F6C66)),
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

  /// Builds a map (DateTime -> average mood score) for the last 7 days of
  /// journal entries. Missing days return 0.0 so the chart maintains shape.
  Map<DateTime, double> _buildMoodData(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, int days) {
    final now = DateTime.now();
    final Map<String, List<double>> dayScores = {};
    for (int i = 0; i < days; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      dayScores[key] = [];
    }
    for (final doc in docs) {
      final data = doc.data();
      final ts = data['createdAt'];
      if (ts is! Timestamp) continue;
      final dt = ts.toDate();
      final dayKey = DateFormat('yyyy-MM-dd').format(DateTime(dt.year, dt.month, dt.day));
      if (!dayScores.containsKey(dayKey)) continue;
      final mood = (data['mood'] ?? 'neutral') as String;
      final score = _moodScore[mood] ?? 2;
      dayScores[dayKey]!.add(score);
    }
    final Map<DateTime, double> result = {};
    for (int i = 0; i < days; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      final scores = dayScores[key]!;
      final avg = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
      result[day] = avg;
    }
    return result;
  }

  Future<void> _showRangeDialog() async {
    final chosen = await showDialog<_MoodRange>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select mood range'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, _MoodRange.seven),
            child: const Text('Last 7 days'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, _MoodRange.thirty),
            child: const Text('Last 30 days'),
          ),
        ],
      ),
    );
    if (chosen != null) {
      setState(() => _range = chosen);
    }
  }
}

/// Card rendering a 7‑day mood trend line.
/// Enhancements:
/// - Smoothed curved line with gradient fill.
/// - Responsive weekday labeling (fewer labels on narrow screens).
/// - Subtle dots + touch overlay disabled for static snapshot.
/// - Zero days kept to preserve line continuity (displayed semi‑transparent).
class _MoodChartCard extends StatelessWidget {
  final Map<DateTime, double> moodData;
  final int days;
  final VoidCallback onSelectRange;
  const _MoodChartCard({required this.moodData, required this.days, required this.onSelectRange});

  @override
  Widget build(BuildContext context) {
    // sort dates ascending so chart goes left→right
    final dates = moodData.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    final spots = <FlSpot>[];

    for (int i = 0; i < dates.length; i++) {
      final d = dates[i];
      final y = moodData[d] ?? 0;
      spots.add(FlSpot(i.toDouble(), y));
    }

    final width = MediaQuery.of(context).size.width;
    // On narrow screens limit bottom labels to first/middle/last for legibility.
    final bool compact = width < 420;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                days == 7 ? '7-day mood curve' : '30-day mood curve',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F2E2C),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Change range',
                onPressed: onSelectRange,
                icon: const Icon(Icons.tune_rounded, size: 20, color: Color(0xFF6F6C66)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 5,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFEDE2D6),
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF6F6C66)),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dates.length) {
                          return const SizedBox.shrink();
                        }
                        if (compact &&
                            index != 0 &&
                            index != dates.length - 1 &&
                            index != (dates.length / 2).floor()) {
                          return const SizedBox.shrink();
                        }
                        final d = dates[index];
                        final pattern = days == 7 ? 'E' : 'd';
                        return Text(
                          DateFormat(pattern).format(d),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF6F6C66)),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.32,
                    barWidth: 3,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF2B8A0), Color(0xFFF5C97B)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isZero = spot.y == 0;
                        return FlDotCirclePainter(
                          radius: 3.5,
                          color: isZero ? const Color(0xFF6F6C66).withValues(alpha: 0.35) : const Color(0xFFF2B8A0),
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF2B8A0).withValues(alpha: 0.28),
                          const Color(0xFFF5C97B).withValues(alpha: 0.10),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Higher = more positive moods',
            style: TextStyle(fontSize: 11, color: Color(0xFF6F6C66)),
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
  const _TimelineEntryTile({required this.title, required this.mood});

  @override
  Widget build(BuildContext context) {
    String emoji = '😊';
    switch (mood) {
      case 'sad':
        emoji = '😢';
        break;
      case 'anxious':
        emoji = '😰';
        break;
      case 'angry':
        emoji = '😠';
        break;
      case 'calm':
        emoji = '😌';
        break;
      case 'neutral':
        emoji = '😐';
        break;
      case 'tired':
        emoji = '🥱';
        break;
      case 'grateful':
        emoji = '🙏';
        break;
      case 'excited':
        emoji = '🤩';
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
