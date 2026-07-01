import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../data/models/game_result.dart';
import 'chart_repository.dart';

import 'package:hive/hive.dart';
import '../cat_bond/cat_bond_store.dart';
import '../data/models/cat_bond.dart';

class GameChartPage extends StatefulWidget {
  const GameChartPage({super.key});

  @override
  State<GameChartPage> createState() => _GameChartPageState();
}

enum StatsTab { overall, game, mindtalk, exercise }

class _GameChartPageState extends State<GameChartPage> {
  final repo = ChartRepository();

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

  late Future<Map<String, double>> _overallFuture;
  late Future<List<GameResult>> _playsFuture;

  @override
  void initState() {
    super.initState();
    _overallFuture = repo.getOverallScoreByGame(games);
    _playsFuture = repo.getByGameAndDifficulty(
      game: _selectedGame,
      difficulty: _selectedDifficulty,
    );
  }

  void _reloadPlays() {
    setState(() {
      _playsFuture = repo.getByGameAndDifficulty(
        game: _selectedGame,
        difficulty: _selectedDifficulty,
      );
    });
  }

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
        return SingleChildScrollView(
          key: const ValueKey('game'),
          child: Column(
            children: [
              _SectionCard(
                title: 'Overview Score',
                height: 280,
                child: FutureBuilder<Map<String, double>>(
                  future: _overallFuture,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _OverallBarChart(games: games, scores: snap.data!);
                  },
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: _selectedGame,
                height: 320,
                child: Column(
                  children: [
                    _SelectorsRow(
                      games: games,
                      selectedGame: _selectedGame,
                      selectedDifficulty: _selectedDifficulty,
                      onGameChanged: (g) {
                        setState(() => _selectedGame = g);
                        _reloadPlays();
                      },
                      onDifficultyChanged: (d) {
                        setState(() => _selectedDifficulty = d);
                        _reloadPlays();
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: FutureBuilder<List<GameResult>>(
                        future: _playsFuture,
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final list = snap.data!;
                          if (list.isEmpty) {
                            return const Center(child: Text('No data'));
                          }
                          return _AccuracyLineChart(results: list);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case StatsTab.overall:
        return _OverallWithCatBondTab(key: const ValueKey('overall'));

      case StatsTab.mindtalk:
        return const _PlaceholderTab(
          key: ValueKey('mindtalk'),
          title: 'MindTalk',
          subtitle: 'รอ map ข้อมูลอารมณ์ (emotion) จากระบบ MindTalk',
        );

      case StatsTab.exercise:
        return const _PlaceholderTab(
          key: ValueKey('exercise'),
          title: 'Exercise',
          subtitle: 'รอ map ข้อมูล exercise score/history',
        );
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
      child: const Text(
        'Statistics',
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
            const Text('Game: ', style: TextStyle(fontWeight: FontWeight.w600)),
            ...games.map(
              (g) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  selected: g == selectedGame,
                  label: Text(g),
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
            const Text(
              'Difficulty: ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...diffs.map(
              (d) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  selected: d == selectedDifficulty,
                  label: Text(d),
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
                  child: Text(games[i], style: const TextStyle(fontSize: 10)),
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

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    super.key,
    required this.title,
    required this.subtitle,
  });
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

class _OverallWithCatBondTab extends StatelessWidget {
  const _OverallWithCatBondTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CatBondStore();

    return SingleChildScrollView(
      child: Column(
        children: [
          _SectionCard(
            title: 'Cat Bond XP',
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
            title: 'Cognitive Domains',
            height: 360,
            child: const _CognitiveDomainsChart(),
          ),
          const SizedBox(height: 16),

          // ถ้าคุณอยากให้ Overall มีอย่างอื่นต่อ ก็วางต่อได้
          const _PlaceholderTab(
            title: 'Overall',
            subtitle: 'แท็บนี้ใช้สรุปรวมทั้งแอป + ความสนิทสนมกับแมว',
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
  const _CognitiveDomainsChart();

  @override
  Widget build(BuildContext context) {
    // TODO: เปลี่ยนเป็นข้อมูลจริงเมื่อพร้อม (จาก repository / service)
    final domains = <_DomainSeries>[
      _DomainSeries('Memory', const Color(0xFFF5821F), [5, 15, 38, 30, 32]),
      _DomainSeries('Attention', const Color(0xFFB23DB5), [12, 8, 20, 10, 35]),
      _DomainSeries('Executive Function', const Color(0xFF5C6FD8), [
        18,
        28,
        24,
        38,
        42,
      ]),
      _DomainSeries('Language', const Color(0xFF3FAE4A), [15, 10, 12, 20, 40]),
      _DomainSeries('Visuospatial', const Color(0xFF4FC3E8), [
        25,
        33,
        42,
        28,
        30,
      ]),
      _DomainSeries('Social Cognition', const Color(0xFFB8DDF5), [
        8,
        18,
        5,
        15,
        25,
      ]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Legend
        Wrap(
          spacing: 14,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: domains
              .map((d) => _LegendDot(color: d.color, label: d.name))
              .toList(),
        ),
        const SizedBox(height: 12),

        // Chart
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 1,
              maxX: 5,
              minY: 0,
              maxY: 50,
              clipData: const FlClipData.all(),
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 10,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 10,
                    getTitlesWidget: (value, meta) {
                      if (value % 10 != 0) return const SizedBox.shrink();
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
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 != 0) return const SizedBox.shrink();
                      final v = value.toInt();
                      if (v < 1 || v > 5) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          v.toString(),
                          style: const TextStyle(
                            fontSize: 13,
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
                ),
              ),
              lineBarsData: domains.map((d) {
                return LineChartBarData(
                  isCurved: true,
                  curveSmoothness: 0.35,
                  preventCurveOverShooting: true,
                  barWidth: 3,
                  color: d.color,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                          radius: 4,
                          color: d.color,
                          strokeWidth: 0,
                        ),
                  ),
                  spots: List.generate(
                    d.values.length,
                    (i) => FlSpot((i + 1).toDouble(), d.values[i].toDouble()),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DomainSeries {
  final String name;
  final Color color;
  final List<num> values;
  _DomainSeries(this.name, this.color, this.values);
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
