// TimelineTab
// Visual + chronological representation of recent journal activity.
// Top section: summary mood trend (last 7/30 days averaged) rendered with a
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

  // Filter docs to only those within the last [days] days based on createdAt.
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocsByDays(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int days,
  ) {
    if (docs.isEmpty) return []; // <-- removed `const`
    final now = DateTime.now();
    return docs.where((doc) {
      final data = doc.data();
      final ts = data['createdAt'];
      if (ts is! Timestamp) return false;
      final dt = ts.toDate();
      // e.g., days = 7 → anything with difference < 7 days
      return now.difference(dt).inDays < days;
    }).toList();
  }

  // Build mood → count map for the given window.
  Map<String, int> _buildMoodCounts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Map<String, int> counts = {};
    for (final doc in docs) {
      final data = doc.data();
      final mood = (data['mood'] ?? 'neutral') as String;
      if (!_moodScore.containsKey(mood)) continue;
      counts[mood] = (counts[mood] ?? 0) + 1;
    }
    return counts;
  }

  // Average mood score over all docs in the window.
  double _computeAverageMood(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) return 0;
    double sum = 0;
    int count = 0;
    for (final doc in docs) {
      final mood = (doc.data()['mood'] ?? 'neutral') as String;
      final score = _moodScore[mood] ?? 2;
      sum += score;
      count++;
    }
    if (count == 0) return 0;
    return sum / count;
  }

  // Build short "pattern insights" strings based on mood data & journaling.
  List<String> _buildInsights({
    required Map<DateTime, double> moodData,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> windowDocs,
    required int days,
  }) {
    final List<String> insights = [];
    if (windowDocs.isEmpty || moodData.isEmpty) {
      return insights;
    }

    final avgMood = _computeAverageMood(windowDocs);
    final counts = _buildMoodCounts(windowDocs);

    // 1) Overall mood level.
    if (avgMood >= 3.5) {
      insights.add(
        'Your overall mood has been mostly positive over the last $days days (average ~${avgMood.toStringAsFixed(1)}/5).',
      );
    } else if (avgMood >= 2.5) {
      insights.add(
        'Your mood has been fairly balanced over the last $days days (average ~${avgMood.toStringAsFixed(1)}/5).',
      );
    } else {
      insights.add(
        'Things have been on the tougher side recently (average mood ~${avgMood.toStringAsFixed(1)}/5 in the last $days days).',
      );
    }

    // 2) Most frequent mood.
    if (counts.isNotEmpty) {
      String topMood =
          counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      // simple label prettifier
      final pretty = topMood[0].toUpperCase() + topMood.substring(1);
      insights.add('You most often felt $pretty during this period.');
    }

    // 3) Journaling consistency (how many days have entries).
    final int totalDays = days <= 0 ? 1 : days; // avoid num from clamp()
    int daysWithEntries = 0;
    for (final entry in moodData.entries) {
      if (entry.value > 0) {
        daysWithEntries++;
      }
    }
    if (totalDays > 0) {
      final consistency = (daysWithEntries / totalDays) * 100;
      insights.add(
        'You journaled on $daysWithEntries of the last $totalDays days (~${consistency.toStringAsFixed(0)}% consistency).',
      );
    }

    // 4) Simple trend check: last 3 days vs previous 3 days.
    final sorted = moodData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (sorted.length >= 6) {
      final last3 = sorted.sublist(sorted.length - 3);
      final prev3 = sorted.sublist(sorted.length - 6, sorted.length - 3);

      double avg(List<MapEntry<DateTime, double>> xs) {
        final vals = xs.map((e) => e.value).where((v) => v > 0).toList();
        if (vals.isEmpty) return 0;
        final s = vals.reduce((a, b) => a + b);
        return s / vals.length;
      }

      final lastAvg = avg(last3);
      final prevAvg = avg(prev3);

      if (lastAvg > 0 && prevAvg > 0) {
        final diff = lastAvg - prevAvg;
        if (diff.abs() >= 0.3) {
          if (diff > 0) {
            insights.add(
              'Your mood has been trending up compared to the previous few days.',
            );
          } else {
            insights.add(
              'Your mood has dipped slightly compared to the previous few days.',
            );
          }
        }
      }
    }

    return insights;
  }

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

        // 2) build mood data for the chart (7 or 30 days)
        final int daysWindow = _range == _MoodRange.seven ? 7 : 30;
        final moodData = _buildMoodData(docs, daysWindow);

        // Filter docs for the same window so stats & insights match the chart.
        final windowDocs = _filterDocsByDays(docs, daysWindow);
        final moodCounts = _buildMoodCounts(windowDocs);
        final avgMood = _computeAverageMood(windowDocs);

        // Best day label (the day with the highest average mood).
        String? bestDayLabel;
        if (moodData.isNotEmpty) {
          final bestEntry =
              moodData.entries.reduce((a, b) => a.value >= b.value ? a : b);
          if (bestEntry.value > 0) {
            bestDayLabel = DateFormat('EEE, MMM d').format(bestEntry.key);
          }
        }

        final insights = _buildInsights(
          moodData: moodData,
          windowDocs: windowDocs,
          days: daysWindow,
        );
        // Consistency for recommended actions.
        int daysWithEntries = 0;
        for (final entry in moodData.entries) {
          if (entry.value > 0) {
            daysWithEntries++;
          }
        }
        final int totalDays = daysWindow <= 0 ? 1 : daysWindow;
        final double consistency =
            totalDays > 0 ? (daysWithEntries / totalDays) * 100 : 0;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 4),
            _MoodChartCard(
              moodData: moodData,
              days: daysWindow,
              onSelectRange: _showRangeDialog,
            ),
            const SizedBox(height: 12),

            // 🧩 Small stats dashboard under the chart
            _MoodStatsRow(
              averageMood: avgMood,
              totalEntries: windowDocs.length,
              dominantMood: moodCounts.entries.isEmpty
                  ? null
                  : moodCounts.entries
                      .reduce((a, b) => a.value >= b.value ? a : b)
                      .key,
              days: daysWindow,
              bestDayLabel: bestDayLabel,
            ),

            const SizedBox(height: 12),

            // 🌡 Mood distribution heatmap
            _MoodHeatmap(
              moodData: moodData,
              days: daysWindow,
            ),

            const SizedBox(height: 12),

            // 🧠 Pattern finder insights card
            if (insights.isNotEmpty)
              _PatternInsightsCard(
                insights: insights,
                days: daysWindow,
              ),

            const SizedBox(height: 12),

            // ✅ Recommended actions based on current patterns
            _RecommendedActionsCard(
              averageMood: avgMood,
              consistency: consistency,
              dominantMood: moodCounts.entries.isEmpty
                  ? null
                  : moodCounts.entries
                      .reduce((a, b) => a.value >= b.value ? a : b)
                      .key,
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

  /// Builds a map (DateTime -> average mood score) for the last [days] days
  /// of journal entries. Missing days return 0.0 so the chart maintains shape.
  Map<DateTime, double> _buildMoodData(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int days,
  ) {
    final now = DateTime.now();
    final Map<String, List<double>> dayScores = {};

    // Initialize buckets for each day in the window.
    for (int i = 0; i < days; i++) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      dayScores[key] = [];
    }

    // Fill scores.
    for (final doc in docs) {
      final data = doc.data();
      final ts = data['createdAt'];
      if (ts is! Timestamp) continue;
      final dt = ts.toDate();
      final dayKey = DateFormat('yyyy-MM-dd')
          .format(DateTime(dt.year, dt.month, dt.day));
      if (!dayScores.containsKey(dayKey)) continue;
      final mood = (data['mood'] ?? 'neutral') as String;
      final score = _moodScore[mood] ?? 2;
      dayScores[dayKey]!.add(score);
    }

    // Compute averages.
    final Map<DateTime, double> result = {};
    for (int i = 0; i < days; i++) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      final scores = dayScores[key]!;
      final avg = scores.isEmpty
          ? 0.0
          : scores.reduce((a, b) => a + b) / scores.length;
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

/// Card rendering a 7/30-day mood trend line.
class _MoodChartCard extends StatelessWidget {
  final Map<DateTime, double> moodData;
  final int days;
  final VoidCallback onSelectRange;
  const _MoodChartCard({
    required this.moodData,
    required this.days,
    required this.onSelectRange,
  });

  @override
  Widget build(BuildContext context) {
    // sort dates ascending so chart goes left→right
    final dates = moodData.keys.toList()..sort((a, b) => a.compareTo(b));
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
                icon: const Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: Color(0xFF6F6C66),
                ),
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
                        if (value % 1 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6F6C66),
                          ),
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
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6F6C66),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                          color: isZero
                              ? const Color(0xFF6F6C66)
                                  .withValues(alpha: 0.35)
                              : const Color(0xFFF2B8A0),
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

/// Compact 3-column stats row under the mood chart.
class _MoodStatsRow extends StatelessWidget {
  final double averageMood;
  final int totalEntries;
  final String? dominantMood;
  final int days;
  final String? bestDayLabel;

  const _MoodStatsRow({
    required this.averageMood,
    required this.totalEntries,
    required this.dominantMood,
    required this.days,
    required this.bestDayLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String avgLabel;
    if (averageMood == 0) {
      avgLabel = '--';
    } else {
      avgLabel = averageMood.toStringAsFixed(1);
    }

    final String entriesLabel =
        totalEntries == 0 ? 'No entries' : '$totalEntries entries';

    final String moodLabel = dominantMood == null
        ? '—'
        : dominantMood![0].toUpperCase() + dominantMood!.substring(1);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _StatChip(
            label: 'Avg mood',
            value: avgLabel,
          ),
          const SizedBox(width: 12),
          _StatChip(
            label: '$days-day entries',
            value: entriesLabel,
            isWide: true,
          ),
          const SizedBox(width: 12),
          _StatChip(
            label: bestDayLabel == null ? 'Top mood' : 'Best day',
            value: bestDayLabel ?? moodLabel,
            isWide: true,
          ),
        ],
      ),
    );
  }
}

/// GitHub-style daily mood heatmap for the selected range.
/// Each square = a day; deeper color = more positive mood.
class _MoodHeatmap extends StatelessWidget {
  final Map<DateTime, double> moodData;
  final int days;

  const _MoodHeatmap({
    required this.moodData,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    if (moodData.isEmpty) return const SizedBox.shrink();

    // Sort dates ascending (oldest → newest).
    final dates = moodData.keys.toList()..sort((a, b) => a.compareTo(b));

    Color colorForValue(double v) {
      if (v <= 0) {
        return const Color(0xFFECE2D8); // "no data / no mood"
      }
      final t = (v / 5).clamp(0.0, 1.0);
      const low = Color(0xFFE4D7CB);
      const high = Color(0xFFF2B8A0);
      return Color.lerp(low, high, t)!;
    }

    String labelForDate(DateTime d, double v) {
      final dayLabel = DateFormat('E, MMM d').format(d);
      return '$dayLabel · ${v.toStringAsFixed(1)}/5';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            days == 7
                ? 'Mood heatmap (last 7 days)'
                : 'Mood heatmap (last $days days)',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F2E2C),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final d in dates)
                if (moodData[d] != null)
                  Tooltip(
                    message: labelForDate(d, moodData[d]!),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colorForValue(moodData[d]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Each square is a day; deeper color means a more positive average mood.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6F6C66),
            ),
          ),
        ],
      ),
    );
  }
}

/// Suggests gentle next steps based on mood + journaling consistency.
class _RecommendedActionsCard extends StatelessWidget {
  final double averageMood;    // 0–5
  final double consistency;    // 0–100 (% of days with entries)
  final String? dominantMood;  // most frequent mood string

  const _RecommendedActionsCard({
    required this.averageMood,
    required this.consistency,
    required this.dominantMood,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> actions = [];

    // Only show if we have at least some data.
    if (averageMood <= 0 && consistency == 0) {
      return const SizedBox.shrink();
    }

    // Mood-based suggestions.
    if (averageMood < 2.5) {
      actions.add(
        'Try using this space for a short daily check-in. Even a couple of sentences can help you notice patterns and feelings.',
      );
      actions.add(
        'On tougher days, you might experiment with a small grounding routine—slow breaths, a short walk, or writing one thing you handled well.',
      );
    } else if (averageMood < 3.5) {
      actions.add(
        'Your mood has been fairly mixed. Pay extra attention to what makes the better days feel lighter—people, activities, or habits you can repeat.',
      );
    } else {
      actions.add(
        'Your recent mood has been mostly positive. Keep noting what supports that—sleep, routines, people—and make them easy to repeat on harder days.',
      );
    }

    // Consistency-based suggestions.
    if (consistency < 40) {
      actions.add(
        'Consider setting a gentle goal, like journaling 2–3 times a week. Keeping it small and realistic makes it easier to stick with.',
      );
    } else if (consistency >= 70) {
      actions.add(
        'You’ve been very consistent with journaling. You could try adding quick tags (like “school”, “friends”, or “sleep”) to deepen future insights.',
      );
    }

    // Mood-specific nudge (non-clinical, gentle).
    if (dominantMood == 'anxious') {
      actions.add(
        'Since anxiety shows up often, it might help to jot down what tends to trigger it and what has helped you feel even a little calmer afterwards.',
      );
    } else if (dominantMood == 'tired') {
      actions.add(
        'Feeling tired a lot? You could track sleep, screen time before bed, and breaks during the day to see what shifts your energy.',
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested next steps',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F2E2C),
            ),
          ),
          const SizedBox(height: 8),
          ...actions.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6F6C66),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A4741),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'If you’re ever feeling really overwhelmed, reaching out to someone you trust or a professional support line can make a big difference.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6F6C66),
            ),
          ),
        ],
      ),
    );
  }
}



class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isWide;

  const _StatChip({
    required this.label,
    required this.value,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      flex: isWide ? 2 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6F6C66),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2F2E2C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pattern finder: short natural-language insights about the selected range.
class _PatternInsightsCard extends StatelessWidget {
  final List<String> insights;
  final int days;

  const _PatternInsightsCard({
    required this.insights,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patterns in the last $days days',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F2E2C),
            ),
          ),
          const SizedBox(height: 8),
          ...insights.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6F6C66),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A4741),
                      ),
                    ),
                  ),
                ],
              ),
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
