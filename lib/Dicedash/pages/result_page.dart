import 'package:flutter/material.dart';
import '../../app_language.dart';
import '../models.dart';
import '../theme/dicedash_theme.dart';
import '../widgets/dicedash_bg.dart';
import 'difficulty_page.dart';

// ✅ เพิ่มเพื่อบันทึกผลลง Hive/Chart
import '../../healthcare/data/chart_store.dart';
import '../../audio/page_voice.dart';
import '../../ble/robot_celebration.dart';

class ResultPage extends StatelessWidget {
  final Difficulty difficulty;
  final int score; // 0..100
  final int correctCount; // 0..5
  final List<RoundResult> results;

  const ResultPage({
    super.key,
    required this.difficulty,
    required this.score,
    required this.correctCount,
    required this.results,
  });

  String get diffLabel => difficulty.label;

  int get totalRounds => results.isNotEmpty ? results.length : 5;

  int get hits => results.where((r) => r.isCorrect).length;

  double get accuracyPercent {
    final total = results.isNotEmpty ? results.length : 5;
    if (total <= 0) return 0;
    return (hits / total) * 100.0;
  }

  String get rankText {
    final acc = accuracyPercent;
    if (acc >= 90) return AppText.get('excellent');
    if (acc >= 75) return AppText.get('good');
    if (acc >= 55) return AppText.get('okay');
    return AppText.get('keepTrying');
  }

  Color _accColor(double acc) {
    if (acc < 25) return const Color(0xFFEF5A5A); // red
    if (acc < 50) return kDiceDashOrange; // orange
    return const Color(0xFF7ED957); // green
  }

  void _goHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DifficultyPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final acc = accuracyPercent.clamp(0, 100).toDouble();
    final accColor = _accColor(acc);

    return Scaffold(
      body: RobotCelebration(
        child: PageVoice(
          assetPath: VoiceAssets.greatJob,
          child: DiceDashBG(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final wide = w >= 900;

                  final cardRadius = 30.0;
                  final borderW = 8.0;

                  final bigTitle = (w / 20).clamp(24.0, 38.0);
                  final bigNumber = (w / 10).clamp(52.0, 96.0);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      children: [
                        // Top Bar
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: kDiceDashOrange,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: alphaColor(Colors.black, 0.14),
                                    blurRadius: 16,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Text(
                                "${AppText.get('result')} • $diffLabel",
                                style: TextStyle(
                                  fontSize: (bigTitle * 0.65).clamp(16.0, 22.0),
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Main Card
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(cardRadius),
                              border: Border.all(
                                color: kDiceDashOrange,
                                width: borderW,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: alphaColor(Colors.black, 0.14),
                                  blurRadius: 24,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: wide
                                ? Row(
                                    children: [
                                      // LEFT: Accuracy
                                      Expanded(
                                        child: _AccuracyPanel(
                                          acc: acc,
                                          bigNumber: bigNumber,
                                          bigTitle: bigTitle,
                                          rankText: rankText,
                                          accColor: accColor,
                                        ),
                                      ),
                                      const SizedBox(width: 18),

                                      // RIGHT: Details table + Home button
                                      SizedBox(
                                        width: (w * 0.46).clamp(380.0, 620.0),
                                        child: _DetailsPanel(
                                          difficulty:
                                              difficulty, // ✅ เพิ่ม (UI ไม่เปลี่ยน)
                                          results: results,
                                          totalRounds: totalRounds,
                                          score: score,
                                          correctCount: correctCount,
                                          onHome: () => _goHome(context),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Expanded(
                                        child: _AccuracyPanel(
                                          acc: acc,
                                          bigNumber: bigNumber,
                                          bigTitle: bigTitle,
                                          rankText: rankText,
                                          accColor: accColor,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      _DetailsPanel(
                                        difficulty:
                                            difficulty, // ✅ เพิ่ม (UI ไม่เปลี่ยน)
                                        results: results,
                                        totalRounds: totalRounds,
                                        score: score,
                                        correctCount: correctCount,
                                        onHome: () => _goHome(context),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccuracyPanel extends StatelessWidget {
  final double acc;
  final double bigNumber;
  final double bigTitle;
  final String rankText;
  final Color accColor;

  const _AccuracyPanel({
    required this.acc,
    required this.bigNumber,
    required this.bigTitle,
    required this.rankText,
    required this.accColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accColor, width: 8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppText.get('accuracy'),
            style: TextStyle(
              fontSize: (bigTitle * 0.9).clamp(20.0, 34.0),
              fontWeight: FontWeight.w900,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CircularProgressIndicator(
                    value: acc / 100.0,
                    strokeWidth: 22,
                    backgroundColor: const Color(0xFFDADADA),
                    valueColor: AlwaysStoppedAnimation<Color>(accColor),
                  ),
                ),
                Text(
                  "${acc.toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: (bigNumber * 0.65).clamp(58.0, 86.0),
                    fontWeight: FontWeight.w900,
                    color: accColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Text(
            rankText,
            style: TextStyle(
              fontSize: (bigTitle * 1.1).clamp(28.0, 44.0),
              fontWeight: FontWeight.w900,
              color: accColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  // ✅ เพิ่ม field เพื่อใช้บันทึก difficulty ได้ (UI ไม่เปลี่ยน)
  final Difficulty difficulty;

  final List<RoundResult> results;
  final int totalRounds;
  final int score;
  final int correctCount;
  final VoidCallback onHome;

  const _DetailsPanel({
    required this.difficulty, // ✅ เพิ่ม
    required this.results,
    required this.totalRounds,
    required this.score,
    required this.correctCount,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    const orange = kDiceDashOrange;

    final safeResults = results.isEmpty ? <RoundResult>[] : results;
    final showCount = safeResults.length.clamp(0, 5);

    return Column(
      children: [
        // Title bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: orange,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: alphaColor(Colors.black, 0.14),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              AppText.get('details'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Table card
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: orange, width: 8),
            ),
            child: Column(
              children: [
                _TableHeader(),
                const SizedBox(height: 10),

                Expanded(
                  child: showCount == 0
                      ? Center(
                          child: Text(
                            AppText.get('noData'),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.black54,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: showCount,
                          separatorBuilder: (_, __) => Divider(
                            height: 14,
                            color: alphaColor(Colors.black, 0.10),
                          ),
                          itemBuilder: (context, i) {
                            final r = safeResults[i];
                            return _TableRowItem(r: r);
                          },
                        ),
                ),

                const SizedBox(height: 12),

                // Summary row
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: alphaColor(orange, 0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: alphaColor(orange, 0.55),
                      width: 3,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        color: orange,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Score: $score / 100",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: orange,
                          ),
                        ),
                      ),
                      Text(
                        "$correctCount / $totalRounds",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Home Button (ใหญ่)  ✅ UI เดิม แต่เพิ่ม logResult ก่อนกลับ home
        SizedBox(
          width: double.infinity,
          height: 120,
          child: ElevatedButton(
            onPressed: () async {
              final hits = results.where((r) => r.isCorrect).length;
              final total = results.isNotEmpty ? results.length : 5;
              final miss = (total - hits).clamp(0, 999999);
              final acc = total == 0 ? 0.0 : (hits / total) * 100.0;

              try {
                await ChartStore().logResult(
                  game: 'dicedash', // ✅ ต้องตรงกับหน้า chart
                  difficulty: difficulty.name,
                  accuracyPercent: acc,
                  hits: hits,
                  miss: miss,
                );
              } catch (_) {}

              if (!context.mounted) return;
              // ✅ กลับแบบเดิมตาม UI/flow เดิม
              Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
              // หรือถ้าคุณอยากกลับหน้า DifficultyPage ของ DiceDash แบบเดิม ให้ใช้:
              // onHome();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: Text(
              AppText.get('home'),
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const orange = kDiceDashOrange;

    Widget head(String t, {int flex = 1, TextAlign align = TextAlign.center}) {
      return Expanded(
        flex: flex,
        child: Text(
          t,
          textAlign: align,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: orange,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: alphaColor(orange, 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alphaColor(orange, 0.50), width: 2),
      ),
      child: Row(
        children: [
          head("R", flex: 1),
          head(AppText.get('question'), flex: 4),
          head(AppText.get('yourAnswer'), flex: 2),
          head(AppText.get('answer'), flex: 2),
          head("✓", flex: 1),
        ],
      ),
    );
  }
}

class _TableRowItem extends StatelessWidget {
  final RoundResult r;
  const _TableRowItem({required this.r});

  @override
  Widget build(BuildContext context) {
    final ok = r.isCorrect;
    final okColor = ok ? const Color(0xFF7ED957) : const Color(0xFFEF5A5A);

    Widget cell(
      String t, {
      int flex = 1,
      TextAlign align = TextAlign.center,
      Color? color,
      double fontSize = 20,
      FontWeight fw = FontWeight.w900,
    }) {
      return Expanded(
        flex: flex,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            t,
            textAlign: align,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fw,
              color: color ?? Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Row(
      children: [
        cell("${r.roundIndex}", flex: 1, color: Colors.black87),
        cell(
          r.question.expression,
          flex: 4,
          color: Colors.black87,
          fontSize: 22,
        ),
        cell("${r.selected}", flex: 2, color: Colors.black87, fontSize: 22),
        cell(
          "${r.question.answer}",
          flex: 2,
          color: Colors.black87,
          fontSize: 22,
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: alphaColor(okColor, 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: alphaColor(okColor, 0.60), width: 3),
              ),
              child: Icon(
                ok ? Icons.check : Icons.close,
                color: okColor,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
