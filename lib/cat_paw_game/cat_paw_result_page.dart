import 'package:flutter/material.dart';
import '../app_language.dart';
import 'cat_paw_difficulty_screen.dart';
import '../audio/page_voice.dart';
import '../ble/robot_celebration.dart';

class CatPawResultPage extends StatelessWidget {
  final CatPawDifficulty difficulty;
  final int hits;
  final int miss;
  final int pawShow;
  final int totalPaw;
  final double accuracyPercent;

  const CatPawResultPage({
    super.key,
    required this.difficulty,
    required this.hits,
    required this.miss,
    required this.pawShow,
    required this.totalPaw,
    required this.accuracyPercent,
  });

  String get diffLabel {
    switch (difficulty) {
      case CatPawDifficulty.easy:
        return AppText.get('easy');
      case CatPawDifficulty.normal:
        return AppText.get('normal');
      case CatPawDifficulty.hard:
        return AppText.get('hard');
    }
  }

  String get rankText {
    if (accuracyPercent >= 90) return AppText.get('excellent');
    if (accuracyPercent >= 75) return AppText.get('good');
    if (accuracyPercent >= 55) return AppText.get('okay');
    return AppText.get('keepTrying');
  }

  @override
  Widget build(BuildContext context) {
    final acc = accuracyPercent.clamp(0, 100).toDouble();

    return Scaffold(
      body: RobotCelebration(
        child: PageVoice(
          assetPath: VoiceAssets.greatJob,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  "assets/bg/catpaw_bg.png",
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFFFFF7F0)),
                ),
              ),
              Positioned.fill(
                child: Container(color: Colors.white.withValues(alpha: 0.1)),
              ),

              SafeArea(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final bool wide = w >= 900;

                    final outerPad = const EdgeInsets.fromLTRB(18, 16, 18, 18);

                    final cardRadius = 28.0;
                    final borderW = 8.0;

                    final bigTitle = (w / 20).clamp(24.0, 38.0);
                    final bigNumber = (w / 10).clamp(52.0, 96.0);

                    return Padding(
                      padding: outerPad,
                      child: Column(
                        children: [
                          // Top Bar (optional)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 16,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "${AppText.get('result')} • $diffLabel",
                                  style: TextStyle(
                                    fontSize: (bigTitle * 0.65).clamp(
                                      16.0,
                                      22.0,
                                    ),
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // back to games
                            ],
                          ),

                          const SizedBox(height: 14),

                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(cardRadius),
                                border: Border.all(
                                  color: const Color(0xFFFF9800),
                                  width: borderW,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 22,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: wide
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: _AccuracyPanel(
                                            acc: acc,
                                            bigNumber: bigNumber,
                                            bigTitle: bigTitle,
                                            rankText: rankText,
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        SizedBox(
                                          width: (w * 0.4).clamp(330.0, 520.0),
                                          child: _RightPanel(
                                            hits: hits,
                                            miss: miss,
                                            pawShow: pawShow,
                                            totalPaw: totalPaw,
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
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        _RightPanel(
                                          hits: hits,
                                          miss: miss,
                                          pawShow: pawShow,
                                          totalPaw: totalPaw,
                                        ),
                                        const SizedBox(height: 16),
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
            ],
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

  const _AccuracyPanel({
    required this.acc,
    required this.bigNumber,
    required this.bigTitle,
    required this.rankText,
  });

  Color _colorByAccuracy(double acc) {
    if (acc < 25) {
      return const Color(0xFFEF5A5A); // red
    } else if (acc < 50) {
      return const Color(0xFFFF9800); // orange
    } else {
      return const Color(0xFF7ED957); // green
    }
  }

  @override
  Widget build(BuildContext context) {
    final accColor = _colorByAccuracy(acc);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        // ✅ กรอบเปลี่ยนสีตามคะแนน
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
                    fontSize: 70,
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

class _RightPanel extends StatelessWidget {
  final int hits;
  final int miss;
  final int pawShow;
  final int totalPaw;

  const _RightPanel({
    required this.hits,
    required this.miss,
    required this.pawShow,
    required this.totalPaw,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF9800);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                title: AppText.get('hits'),
                value: hits.toString(),
                valueColor: const Color(0xFF7ED957),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                title: AppText.get('miss'),
                value: miss.toString(),
                valueColor: const Color(0xFFEF5A5A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: orange,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              AppText.get('total'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ✅ กล่อง Paw Show / Total Paw
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: orange, width: 8),
          ),
          child: Column(
            children: [
              _RowKV(label: AppText.get('pawShow'), value: pawShow.toString()),
              const SizedBox(height: 18),
              _RowKV(
                label: AppText.get('totalPaw'),
                value: totalPaw.toString(),
              ),
            ],
          ),
        ),

        // ✅ ปุ่ม Home อยู่ “ด้านล่างกล่องนี้”
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 120,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange, // สีพื้น
              foregroundColor: Colors.white,
              elevation: 0, // ให้เหมือนกล่อง
              minimumSize: const Size.fromHeight(12),
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

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _MiniStat({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFF9800), width: 8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowKV extends StatelessWidget {
  final String label;
  final String value;

  const _RowKV({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF9800);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: orange,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: orange,
          ),
        ),
      ],
    );
  }
}
