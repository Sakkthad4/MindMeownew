import 'package:flutter/material.dart';
import '../app_language.dart';
import 'package:fl_chart/fl_chart.dart';

import 'data/chart_store.dart';
import 'data/cat_bond_store.dart';
import 'data/cognitive_domain_statistics.dart';
import 'data/exercise_session_store.dart';
import 'data/exercise_statistics.dart';
import 'data/mindtalk_emotion_store.dart';
import 'models/cat_bond.dart';
import 'models/exercise_session.dart';
import 'models/game_result.dart';
import 'models/mindtalk_emotion_event.dart';

import 'package:hive/hive.dart';

class HealthcarePage extends StatefulWidget {
  const HealthcarePage({super.key});

  @override
  State<HealthcarePage> createState() => _HealthcarePageState();
}

enum StatsTab { overall, game, mindtalk, exercise }

class _HealthcarePageState extends State<HealthcarePage> {
  // ✅ เปิดมาที่ Overall
  StatsTab _tab = StatsTab.overall;

  // ชื่อ game ต้องตรงกับที่คุณ logResult(game: '...')
  final List<String> games = const [
    'supermarket',
    'dicedash',
    'catpaw',
    'drawvis',
  ];

  String _selectedGame = 'supermarket';
  String _selectedDifficulty = 'easy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              _HeaderTitle(),
              const SizedBox(height: 14),
              _TabBarRow(
                current: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _buildTabBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_tab) {
      case StatsTab.game:
        return ValueListenableBuilder<Box<GameResult>>(
          key: const ValueKey('game'),
          valueListenable: ChartStore().listenable(),
          builder: (context, box, _) {
            final allResults = box.values.toList();
            final scores = <String, double>{};
            for (final game in games) {
              final results = allResults
                  .where((result) => result.game == game)
                  .toList();
              scores[game] = results.isEmpty
                  ? 0
                  : results
                            .map((result) => result.accuracy)
                            .reduce((left, right) => left + right) /
                        results.length;
            }
            final selectedResults =
                allResults
                    .where(
                      (result) =>
                          result.game == _selectedGame &&
                          result.difficulty == _selectedDifficulty,
                    )
                    .toList()
                  ..sort(
                    (left, right) => left.playedAt.compareTo(right.playedAt),
                  );

            return SingleChildScrollView(
              child: Column(
                children: [
                  _SectionCard(
                    title: AppText.get('overviewScore'),
                    height: 280,
                    child: _OverallBarChart(games: games, scores: scores),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: AppText.name(_selectedGame),
                    height: 320,
                    child: Column(
                      children: [
                        _SelectorsRow(
                          games: games,
                          selectedGame: _selectedGame,
                          selectedDifficulty: _selectedDifficulty,
                          onGameChanged: (game) =>
                              setState(() => _selectedGame = game),
                          onDifficultyChanged: (difficulty) =>
                              setState(() => _selectedDifficulty = difficulty),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: selectedResults.isEmpty
                              ? Center(child: Text(AppText.get('noData')))
                              : _AccuracyLineChart(results: selectedResults),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );

      case StatsTab.overall:
        return _OverallWithCatBondTab(key: const ValueKey('overall'));

      case StatsTab.mindtalk:
        return const _MindTalkEmotionTab(key: ValueKey('mindtalk'));

      case StatsTab.exercise:
        return const _ExerciseStatisticsTab(key: ValueKey('exercise'));
    }
  }
}

class _HeaderTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFA63B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE67E22), width: 3),
      ),
      child: Text(
        AppText.get('statistics'),
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _TabBarRow extends StatelessWidget {
  const _TabBarRow({required this.current, required this.onChanged});

  final StatsTab current;
  final ValueChanged<StatsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tabButton(String text, StatsTab tab) {
      final selected = current == tab;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: InkWell(
            onTap: () => onChanged(tab),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFFA63B)
                    : const Color(0xFFFFD39A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE67E22), width: 2),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tabButton('Overall', StatsTab.overall),
        tabButton('Game', StatsTab.game),
        tabButton('MindTalk', StatsTab.mindtalk),
        tabButton('Exercise', StatsTab.exercise),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.height,
  });

  final String title;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6),
        border: Border.all(color: const Color(0xFFE67E22), width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SelectorsRow extends StatelessWidget {
  const _SelectorsRow({
    required this.games,
    required this.selectedGame,
    required this.selectedDifficulty,
    required this.onGameChanged,
    required this.onDifficultyChanged,
  });

  final List<String> games;
  final String selectedGame;
  final String selectedDifficulty;
  final ValueChanged<String> onGameChanged;
  final ValueChanged<String> onDifficultyChanged;

  @override
  Widget build(BuildContext context) {
    const diffs = ['easy', 'normal', 'hard'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppText.get('game')}: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            ...games.map(
              (g) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  selected: g == selectedGame,
                  label: Text(AppText.name(g)),
                  onSelected: (_) => onGameChanged(g),
                  selectedColor: const Color(0xFFFFC27A),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE67E22)),
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppText.get('difficulty')}: ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...diffs.map(
              (d) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  selected: d == selectedDifficulty,
                  label: Text(
                    AppText.get(
                      d == 'easy'
                          ? 'easy'
                          : d == 'normal'
                          ? 'normal'
                          : 'hard',
                    ),
                  ),
                  onSelected: (_) => onDifficultyChanged(d),
                  selectedColor: const Color(0xFFFFC27A),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE67E22)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverallBarChart extends StatelessWidget {
  const _OverallBarChart({required this.games, required this.scores});

  final List<String> games;
  final Map<String, double> scores;

  @override
  Widget build(BuildContext context) {
    final values = games.map((g) => scores[g] ?? 0).toList();
    final maxVal = values.isEmpty
        ? 100.0
        : values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal * 1.2).clamp(10.0, 100.0);

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 44),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1, // ✅ บังคับให้ tick เป็นจำนวนเต็ม
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return const SizedBox.shrink();
                final i = value.toInt();
                if (i < 0 || i >= games.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    AppText.name(games[i]),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(games.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                width: 26,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _AccuracyLineChart extends StatelessWidget {
  const _AccuracyLineChart({required this.results});
  final List<GameResult> results;

  @override
  Widget build(BuildContext context) {
    final sorted = [...results]
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));

    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      // x = 1,2,3,... (integer only)
      spots.add(FlSpot((i + 1).toDouble(), sorted[i].accuracy.clamp(0, 100)));
    }

    // ✅ ทำให้ maxX เป็นจำนวนเต็มเสมอ และมีขั้นต่ำ 5
    final double maxX = spots.isEmpty ? 5.0 : spots.last.x.ceilToDouble();
    final double chartMaxX = maxX < 5 ? 5 : maxX;

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: chartMaxX,
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),

        // ✅ เอา const ออก เพื่อใส่ getTitlesWidget + interval
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 44),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1, // ✅ บังคับแกน X ทีละ 1
              getTitlesWidget: (value, meta) {
                // ✅ แสดงเฉพาะจำนวนเต็ม -> ไม่มี 1.1/1.2 แน่นอน
                if (value % 1 != 0) return const SizedBox.shrink();

                final v = value.toInt();
                // กันค่าหลุดช่วง (เช่น 0 หรือ > max)
                if (v < 1 || v > chartMaxX.toInt()) {
                  return const SizedBox.shrink();
                }

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 6,
                  child: Text(
                    v.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.black54,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            barWidth: 4,
            dotData: const FlDotData(show: true),
            spots: spots,
          ),
        ],
      ),
    );
  }
}

class _ExerciseStatisticsTab extends StatelessWidget {
  const _ExerciseStatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ExerciseSessionStore();
    return ValueListenableBuilder<Box<ExerciseSession>>(
      valueListenable: store.listenable(),
      builder: (context, box, _) {
        final stats = ExerciseStatistics.from(box.values);
        if (stats.sessions == 0) {
          return _PlaceholderTab(
            title: AppText.get('exerciseStatistics'),
            subtitle: AppText.get('noExerciseData'),
          );
        }

        final minutes = (stats.totalSeconds / 60).ceil();
        return SingleChildScrollView(
          child: Column(
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _EmotionSummaryCard(
                    icon: Icons.directions_run_rounded,
                    label: AppText.get('exerciseSessions'),
                    value: stats.sessions.toString(),
                    color: const Color(0xFFFFA63B),
                  ),
                  _EmotionSummaryCard(
                    icon: Icons.emoji_events_rounded,
                    label: AppText.get('completedRoutines'),
                    value: stats.completedRoutines.toString(),
                    color: const Color(0xFF63C97A),
                  ),
                  _EmotionSummaryCard(
                    icon: Icons.accessibility_new_rounded,
                    label: AppText.get('completedPoses'),
                    value: stats.completedPoses.toString(),
                    color: const Color(0xFF5C9FE8),
                  ),
                  _EmotionSummaryCard(
                    icon: Icons.check_circle_outline_rounded,
                    label: AppText.get('completionRate'),
                    value:
                        '${(stats.completionRate * 100).round().toString()}%',
                    color: const Color(0xFF8A8FDB),
                  ),
                  _EmotionSummaryCard(
                    icon: Icons.stars_rounded,
                    label: AppText.get('averageScore'),
                    value: stats.averageScore.round().toString(),
                    color: const Color(0xFFF2AD4B),
                  ),
                  _EmotionSummaryCard(
                    icon: Icons.timer_outlined,
                    label: AppText.get('totalExerciseTime'),
                    value: '$minutes ${AppText.get('minutesShort')}',
                    color: const Color(0xFFE86B62),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: AppText.get('weeklyActivity'),
                height: 300,
                child: _ExerciseActivityChart(
                  dailySessions: stats.dailySessions,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExerciseActivityChart extends StatelessWidget {
  const _ExerciseActivityChart({required this.dailySessions});

  final Map<DateTime, int> dailySessions;

  @override
  Widget build(BuildContext context) {
    final entries = dailySessions.entries.toList();
    final highest = entries.fold<int>(
      1,
      (current, entry) => entry.value > current ? entry.value : current,
    );
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final entry in entries)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: entry.value == 0
                          ? 0.04
                          : entry.value / highest,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 6),
                        decoration: BoxDecoration(
                          color: entry.value == 0
                              ? const Color(0xFFFFDDB4)
                              : const Color(0xFFFFA63B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weekdays[entry.key.weekday % 7],
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MindTalkEmotionTab extends StatelessWidget {
  const _MindTalkEmotionTab({super.key});

  static const _colors = {
    MindTalkEmotion.happy: Color(0xFF63C97A),
    MindTalkEmotion.neutral: Color(0xFF63A9E8),
    MindTalkEmotion.sad: Color(0xFF8A8FDB),
    MindTalkEmotion.angry: Color(0xFFE86B62),
    MindTalkEmotion.anxious: Color(0xFFF2AD4B),
  };

  String _label(MindTalkEmotion emotion) => AppText.get(emotion.name);

  @override
  Widget build(BuildContext context) {
    final store = MindTalkEmotionStore();
    return ValueListenableBuilder<Box<MindTalkEmotionEvent>>(
      valueListenable: store.listenable(),
      builder: (context, box, _) {
        final events = store.recent();
        if (events.isEmpty) {
          return _PlaceholderTab(
            title: AppText.get('mindTalk'),
            subtitle:
                '${AppText.get('noEmotionData')}\n\n'
                '${AppText.get('emotionPrivacyNote')}',
          );
        }

        final counts = <MindTalkEmotion, int>{
          for (final emotion in MindTalkEmotion.values) emotion: 0,
        };
        for (final event in events) {
          counts[event.emotionValue] = counts[event.emotionValue]! + 1;
        }
        final conversationCount = events
            .where(
              (event) =>
                  event.sourceValue == MindTalkEmotionSource.conversation,
            )
            .length;
        final cameraCount = events.length - conversationCount;
        final dominant = counts.entries.reduce(
          (left, right) => left.value >= right.value ? left : right,
        );

        return SingleChildScrollView(
          child: Column(
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _EmotionSummaryCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: AppText.get('conversationSignals'),
                    value: conversationCount.toString(),
                    color: const Color(0xFFFFA63B),
                  ),
                  _EmotionSummaryCard(
                    icon: Icons.camera_alt_outlined,
                    label: AppText.get('cameraObservations'),
                    value: cameraCount.toString(),
                    color: const Color(0xFF5C9FE8),
                  ),
                  _EmotionSummaryCard(
                    icon: Icons.favorite_rounded,
                    label: AppText.get('emotionOverview'),
                    value: _label(dominant.key),
                    color: _colors[dominant.key]!,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: AppText.get('emotionOverview'),
                height: 360,
                child: Column(
                  children: [
                    for (final emotion in MindTalkEmotion.values) ...[
                      _EmotionDistributionRow(
                        label: _label(emotion),
                        count: counts[emotion]!,
                        total: events.length,
                        color: _colors[emotion]!,
                      ),
                      const SizedBox(height: 10),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppText.get('emotionPrivacyNote')} '
                            '${AppText.get('emotionEstimateNote')}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmotionSummaryCard extends StatelessWidget {
  const _EmotionSummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionDistributionRow extends StatelessWidget {
  const _EmotionDistributionRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 14,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 54,
          child: Text(
            '${(fraction * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE67E22), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _OverallWithCatBondTab extends StatefulWidget {
  const _OverallWithCatBondTab({super.key});

  @override
  State<_OverallWithCatBondTab> createState() => _OverallWithCatBondTabState();
}

class _OverallWithCatBondTabState extends State<_OverallWithCatBondTab> {
  CognitiveTimeScale _scale = CognitiveTimeScale.week;
  DateTime _anchor = DateTime.now();

  void _movePeriod(int direction) {
    setState(() {
      _anchor = switch (_scale) {
        CognitiveTimeScale.hour => _anchor.add(Duration(hours: direction)),
        CognitiveTimeScale.day => _anchor.add(Duration(days: direction)),
        CognitiveTimeScale.week => _anchor.add(Duration(days: 7 * direction)),
        CognitiveTimeScale.month => DateTime(
          _anchor.year,
          _anchor.month + direction,
          1,
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = CatBondStore();

    return SingleChildScrollView(
      child: Column(
        children: [
          _SectionCard(
            title: AppText.get('catBondXp'),
            height: 220,
            child: ValueListenableBuilder<Box<CatBond>>(
              valueListenable: store.listenable(),
              builder: (context, box, _) {
                final progress = store.getProgress();
                return _CatBondXpCard(progress: progress);
              },
            ),
          ),
          const SizedBox(height: 16),

          // ✅ กราฟใหม่: Cognitive Domains
          _SectionCard(
            title: AppText.get('cognitiveDomains'),
            height: 520,
            child: ValueListenableBuilder<Box<GameResult>>(
              valueListenable: ChartStore().listenable(),
              builder: (context, gameBox, _) {
                return ValueListenableBuilder<Box<MindTalkEmotionEvent>>(
                  valueListenable: MindTalkEmotionStore().listenable(),
                  builder: (context, emotionBox, _) {
                    return ValueListenableBuilder<Box<ExerciseSession>>(
                      valueListenable: ExerciseSessionStore().listenable(),
                      builder: (context, exerciseBox, _) {
                        return _CognitiveDomainsChart(
                          results: gameBox.values.toList(),
                          mindTalkEvents: emotionBox.values.toList(),
                          exerciseSessions: exerciseBox.values.toList(),
                          scale: _scale,
                          anchor: _anchor,
                          onScaleChanged: (scale) {
                            setState(() {
                              _scale = scale;
                              _anchor = DateTime.now();
                            });
                          },
                          onPrevious: () => _movePeriod(-1),
                          onNext: () => _movePeriod(1),
                        );
                      },
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

class _CatBondXpCard extends StatelessWidget {
  const _CatBondXpCard({required this.progress});
  final CatBondProgress progress;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFFA63B);
    const orangeDark = Color(0xFFE67E22);

    final percent = progress.percent; // 0..1
    final xpText = "${progress.xpInLevel} / ${progress.needForLevel} XP";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: orangeDark, width: 2),
      ),
      child: Row(
        children: [
          // ไอคอนแมว (ถ้าคุณมี asset ก็เปลี่ยนเป็น Image.asset ได้)
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: orangeDark, width: 2),
            ),
            child: const Icon(Icons.pets, color: orangeDark, size: 34),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level + total
                Row(
                  children: [
                    Text(
                      "Lv.${progress.level}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: orangeDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Total: ${progress.totalXp} XP",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 18,
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: const Color(0xFFFFE4C4),
                      valueColor: const AlwaysStoppedAnimation<Color>(orange),
                      minHeight: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  xpText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ปุ่มทดสอบเพิ่ม XP (จะลบได้ภายหลัง)
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () async {
                await CatBondStore().addXp(amount: 10, source: 'debug');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "+10",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// ✅ NEW: Cognitive Domains multi-line chart (for Overall tab)
// ────────────────────────────────────────────────────────────────

class _CognitiveDomainsChart extends StatelessWidget {
  const _CognitiveDomainsChart({
    required this.results,
    required this.mindTalkEvents,
    required this.exerciseSessions,
    required this.scale,
    required this.anchor,
    required this.onScaleChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final List<GameResult> results;
  final List<MindTalkEmotionEvent> mindTalkEvents;
  final List<ExerciseSession> exerciseSessions;
  final CognitiveTimeScale scale;
  final DateTime anchor;
  final ValueChanged<CognitiveTimeScale> onScaleChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final statistics = CognitiveDomainStatistics.from(
      games: results,
      mindTalkEvents: mindTalkEvents,
      exerciseSessions: exerciseSessions,
      scale: scale,
      anchor: anchor,
    );
    final domains = <_DomainSeries>[
      _DomainSeries(
        AppText.get('memoryDomain'),
        const Color(0xFFF5821F),
        statistics.scores[CognitiveDomain.memory]!,
      ),
      _DomainSeries(
        AppText.get('attentionDomain'),
        const Color(0xFFB23DB5),
        statistics.scores[CognitiveDomain.attention]!,
      ),
      _DomainSeries(
        AppText.get('executiveFunctionDomain'),
        const Color(0xFF5C6FD8),
        statistics.scores[CognitiveDomain.executiveFunction]!,
      ),
      _DomainSeries(
        AppText.get('languageDomain'),
        const Color(0xFF3FAE4A),
        statistics.scores[CognitiveDomain.language]!,
      ),
      _DomainSeries(
        AppText.get('visuospatialDomain'),
        const Color(0xFF4FC3E8),
        statistics.scores[CognitiveDomain.visuospatial]!,
      ),
      _DomainSeries(
        AppText.get('socialCognitionDomain'),
        const Color(0xFF79A9D1),
        statistics.scores[CognitiveDomain.socialCognition]!,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CognitivePeriodControls(
          scale: scale,
          periodStart: statistics.periodStart,
          onScaleChanged: onScaleChanged,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
        const SizedBox(height: 10),
        // Legend
        Wrap(
          spacing: 10,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: domains
              .map((d) => _LegendDot(color: d.color, label: d.name))
              .toList(),
        ),
        const SizedBox(height: 6),
        Text(
          AppText.get('cognitiveIndicatorNote'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),

        // Chart
        Expanded(
          child: statistics.hasData
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 12, 2),
                  child: LineChart(_chartData(statistics, domains)),
                )
              : Center(
                  child: Text(
                    AppText.get('noCognitiveDataForPeriod'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
        ),
      ],
    );
  }

  LineChartData _chartData(
    CognitiveDomainStatistics statistics,
    List<_DomainSeries> domains,
  ) {
    final labelInterval = switch (scale) {
      CognitiveTimeScale.hour => 10,
      CognitiveTimeScale.day => 4,
      CognitiveTimeScale.week => 1,
      CognitiveTimeScale.month => 5,
    };

    return LineChartData(
      minX: -0.35,
      maxX: statistics.labels.length - 0.65,
      minY: -3,
      maxY: 103,
      clipData: const FlClipData.all(),
      gridData: const FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 20,
            getTitlesWidget: (value, meta) {
              if (value % 20 != 0) return const SizedBox.shrink();
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value % 1 != 0) return const SizedBox.shrink();
              final index = value.toInt();
              if (index < 0 ||
                  index >= statistics.labels.length ||
                  index % labelInterval != 0) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 7,
                child: Text(
                  statistics.labels[index],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black54,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => Colors.black87,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
        ),
      ),
      lineBarsData: domains.where((d) => d.hasData).map((d) {
        return LineChartBarData(
          isCurved: false,
          barWidth: 3,
          color: d.color,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) =>
                FlDotCirclePainter(radius: 4, color: d.color, strokeWidth: 0),
          ),
          spots: List.generate(
            d.values.length,
            (i) => d.values[i] == null
                ? FlSpot.nullSpot
                : FlSpot(i.toDouble(), d.values[i]!),
          ),
        );
      }).toList(),
    );
  }
}

class _CognitivePeriodControls extends StatelessWidget {
  const _CognitivePeriodControls({
    required this.scale,
    required this.periodStart,
    required this.onScaleChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final CognitiveTimeScale scale;
  final DateTime periodStart;
  final ValueChanged<CognitiveTimeScale> onScaleChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  String _scaleLabel(CognitiveTimeScale value) => AppText.get(switch (value) {
    CognitiveTimeScale.hour => 'hour',
    CognitiveTimeScale.day => 'day',
    CognitiveTimeScale.week => 'week',
    CognitiveTimeScale.month => 'month',
  });

  String _periodLabel() {
    final date = '${periodStart.day}/${periodStart.month}/${periodStart.year}';
    return switch (scale) {
      CognitiveTimeScale.hour =>
        '$date  ${periodStart.hour.toString().padLeft(2, '0')}:00',
      CognitiveTimeScale.day => date,
      CognitiveTimeScale.week =>
        '$date – '
            '${periodStart.add(const Duration(days: 6)).day}/'
            '${periodStart.add(const Duration(days: 6)).month}/'
            '${periodStart.add(const Duration(days: 6)).year}',
      CognitiveTimeScale.month =>
        '${AppText.month(periodStart.month)} ${periodStart.year}',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final value in CognitiveTimeScale.values)
              ChoiceChip(
                selected: value == scale,
                label: Text(_scaleLabel(value)),
                onSelected: (_) => onScaleChanged(value),
                selectedColor: const Color(0xFFFFC27A),
                backgroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: AppText.get('previousPeriod'),
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 190),
              child: Text(
                _periodLabel(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: AppText.get('nextPeriod'),
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _DomainSeries {
  final String name;
  final Color color;
  final List<double?> values;
  _DomainSeries(this.name, this.color, this.values);

  bool get hasData => values.any((value) => value != null);
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}
