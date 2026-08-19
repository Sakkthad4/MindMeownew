import 'package:flutter/material.dart';
import '../models.dart';
import '../question_engine.dart';
import '../theme/dicedash_theme.dart';
import '../widgets/dicedash_bg.dart';
import '../widgets/choice_tile.dart';
import '../widgets/dice_widget.dart';
import 'result_page.dart';
import '../../audio/soundeffect.dart';
import '../../audio/page_voice.dart';

class GamePage extends StatefulWidget {
  final Difficulty difficulty;
  const GamePage({super.key, required this.difficulty});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const int totalRounds = 5;

  final engine = DiceDashEngine();

  int round = 1;
  int score = 0;
  int correctCount = 0;

  DiceQuestion? current;
  bool locked = false;
  int? selected;

  final List<RoundResult> results = [];

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    setState(() {
      locked = false;
      selected = null;
      current = engine.generateQuestion(widget.difficulty);
    });
  }

  Future<void> _choose(int v) async {
    if (locked || current == null) return;
    final q = current!;
    final ok = v == q.answer;

    if (ok) {
      SoundFx.play(SoundFx.correct, volume: SoundFx.correctVolume);
    } else {
      SoundFx.play(SoundFx.incorrect, volume: SoundFx.incorrectVolume);
    }

    setState(() {
      locked = true;
      selected = v;
    });

    results.add(
      RoundResult(roundIndex: round, question: q, selected: v, isCorrect: ok),
    );

    if (ok) {
      score += 20;
      correctCount += 1;
    }

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    if (round >= totalRounds) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            difficulty: widget.difficulty,
            score: score,
            correctCount: correctCount,
            results: results,
          ),
        ),
      );
    } else {
      setState(() => round += 1);
      _newRound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = current;

    return Scaffold(
      body: PageVoice(
        assetPath: VoiceAssets.doSomeMath,
        child: DiceDashBG(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final wide = w >= 900;

                final double headerH = (c.maxHeight * 0.22).clamp(150.0, 240.0);
                final double eqBoxH = (c.maxHeight * 0.26).clamp(140.0, 220.0);

                final double choiceH = wide
                    ? 170
                    : 140; // ปุ่มใหญ่สำหรับผู้สูงวัย
                final double gap = wide ? 26 : 16;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    children: [
                      // Top bar (รอบ + คะแนน)
                      Row(
                        children: [
                          _TopPill(text: 'Round $round/$totalRounds'),
                          const SizedBox(width: 10),
                          _TopPill(text: widget.difficulty.label),
                          const Spacer(),
                          _ScorePill(score: score),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Equation big box (เหมือนภาพ)
                      Container(
                        height: headerH,
                        alignment: Alignment.center,
                        child: Container(
                          height: eqBoxH,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                              color: kDiceDashOrange,
                              width: 8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: alphaColor(Colors.black, 0.12),
                                blurRadius: 22,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: q == null
                              ? const SizedBox()
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    DiceFace(value: q.a, size: wide ? 110 : 96),
                                    const SizedBox(width: 18),
                                    Text(
                                      q.op,
                                      style: TextStyle(
                                        fontSize: wide ? 62 : 56,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    DiceFace(value: q.b, size: wide ? 110 : 96),
                                    const SizedBox(width: 18),
                                    Text(
                                      '=',
                                      style: TextStyle(
                                        fontSize: wide ? 62 : 56,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    Text(
                                      '?',
                                      style: TextStyle(
                                        fontSize: wide ? 72 : 64,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Choices 4 ช่อง
                      if (q != null)
                        Expanded(
                          child: wide
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: ChoiceTile(
                                              value: q.choices[0],
                                              height: choiceH,
                                              locked: locked,
                                              selected:
                                                  selected == q.choices[0],
                                              correct: q.answer,
                                              onTap: () =>
                                                  _choose(q.choices[0]),
                                            ),
                                          ),
                                          SizedBox(height: gap),
                                          Expanded(
                                            child: ChoiceTile(
                                              value: q.choices[2],
                                              height: choiceH,
                                              locked: locked,
                                              selected:
                                                  selected == q.choices[2],
                                              correct: q.answer,
                                              onTap: () =>
                                                  _choose(q.choices[2]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: gap),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: ChoiceTile(
                                              value: q.choices[1],
                                              height: choiceH,
                                              locked: locked,
                                              selected:
                                                  selected == q.choices[1],
                                              correct: q.answer,
                                              onTap: () =>
                                                  _choose(q.choices[1]),
                                            ),
                                          ),
                                          SizedBox(height: gap),
                                          Expanded(
                                            child: ChoiceTile(
                                              value: q.choices[3],
                                              height: choiceH,
                                              locked: locked,
                                              selected:
                                                  selected == q.choices[3],
                                              correct: q.answer,
                                              onTap: () =>
                                                  _choose(q.choices[3]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: ChoiceTile(
                                              value: q.choices[0],
                                              height: choiceH,
                                              locked: locked,
                                              selected:
                                                  selected == q.choices[0],
                                              correct: q.answer,
                                              onTap: () =>
                                                  _choose(q.choices[0]),
                                            ),
                                          ),
                                          SizedBox(width: gap),
                                          Expanded(
                                            child: ChoiceTile(
                                              value: q.choices[1],
                                              height: choiceH,
                                              locked: locked,
                                              selected:
                                                  selected == q.choices[1],
                                              correct: q.answer,
                                              onTap: () =>
                                                  _choose(q.choices[1]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: gap),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: ChoiceTile(
                                              value: q.choices[2],
                                              height: choiceH,
                                              locked: locked,
                                              selected:
                                                  selected == q.choices[2],
                                              correct: q.answer,
                                              onTap: () =>
                                                  _choose(q.choices[2]),
                                            ),
                                          ),
                                          SizedBox(width: gap),
                                          Expanded(
                                            child: ChoiceTile(
                                              value: q.choices[3],
                                              height: choiceH,
                                              locked: locked,
                                              selected:
                                                  selected == q.choices[3],
                                              correct: q.answer,
                                              onTap: () =>
                                                  _choose(q.choices[3]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  final String text;
  const _TopPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kDiceDashOrange, width: 4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: kDiceDashOrange,
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final int score;
  const _ScorePill({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kDiceDashOrange, width: 4),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            color: kDiceDashOrange,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: kDiceDashOrange,
            ),
          ),
        ],
      ),
    );
  }
}
