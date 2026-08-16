import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../app_language.dart';

import '../healthcare/data/chart_store.dart';
import 'cat_paw_difficulty_screen.dart';
import 'cat_paw_result_page.dart';
import '../healthcare/data/cat_bond_store.dart';

class CatPawGamePage extends StatefulWidget {
  final CatPawDifficulty difficulty;
  const CatPawGamePage({super.key, required this.difficulty});

  @override
  State<CatPawGamePage> createState() => _CatPawGamePageState();
}

class _CatPawGamePageState extends State<CatPawGamePage> {
  // -------- CONFIG --------
  static const int gameSeconds = 40;

  // positions 10 จุด (3-4-3) ในกระดาน
  final List<Offset> _cells = const [
    // row 1 (3)
    Offset(0.20, 0.22),
    Offset(0.50, 0.22),
    Offset(0.80, 0.22),
    // row 2 (4)
    Offset(0.15, 0.50),
    Offset(0.38, 0.50),
    Offset(0.62, 0.50),
    Offset(0.85, 0.50),
    // row 3 (3)
    Offset(0.20, 0.78),
    Offset(0.50, 0.78),
    Offset(0.80, 0.78),
  ];

  final _rng = Random();

  Timer? _countdown;
  Timer? _spawnTimer;
  Timer? _hideTimer;

  int _timeLeft = gameSeconds;
  int _hits = 0;
  int _miss = 0;
  int _totalPaw = 0;

  int _activeIndex = -1;
  bool _showing = false;

  bool _isEnding = false;

  double get _showDurationSec {
    switch (widget.difficulty) {
      case CatPawDifficulty.easy:
        return 1.8;
      case CatPawDifficulty.normal:
        return 1.3;
      case CatPawDifficulty.hard:
        return 0.8;
    }
  }

  // ช่วงเวลาระหว่างการโผล่ (ให้มีหายใจนิดหน่อย)
  double get _spawnEverySec => max(0.75, _showDurationSec + 0.25);

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _spawnTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _start() {
    _timeLeft = gameSeconds;
    _hits = 0;
    _miss = 0;
    _totalPaw = 0;
    _activeIndex = -1;
    _showing = false;
    _isEnding = false;

    _countdown?.cancel();
    _spawnTimer?.cancel();
    _hideTimer?.cancel();

    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isEnding) return;
      setState(() => _timeLeft = (_timeLeft - 1).clamp(0, gameSeconds));
      if (_timeLeft == 0) {
        _finish();
      }
    });

    _spawnTimer = Timer.periodic(
      Duration(milliseconds: (_spawnEverySec * 1000).round()),
      (_) => _spawn(),
    );

    _spawn();
  }

  void _spawn() {
    if (_isEnding || _timeLeft <= 0) return;

    // ถ้ายังแสดงอยู่แล้ว spawn ใหม่ -> ถือว่าพลาด
    if (_showing) _miss++;

    int next = _rng.nextInt(_cells.length);
    if (_cells.length > 1) {
      while (next == _activeIndex) {
        next = _rng.nextInt(_cells.length);
      }
    }

    _totalPaw++;
    _activeIndex = next;
    _showing = true;
    setState(() {});

    _hideTimer?.cancel();
    _hideTimer = Timer(
      Duration(milliseconds: (_showDurationSec * 1000).round()),
      () {
        if (!mounted || _isEnding) return;
        if (_showing) {
          _miss++;
          _showing = false;
          setState(() {});
        }
      },
    );
  }

  void _tapCell(int index) {
    if (_isEnding || _timeLeft <= 0) return;

    if (_showing && index == _activeIndex) {
      _hits++;
      _showing = false;
      _hideTimer?.cancel();
      setState(() {});
    } else {
      _miss++;
      setState(() {});
    }
  }

  Future<void> _finish() async {
    if (_isEnding) return;
    _isEnding = true;

    _countdown?.cancel();
    _spawnTimer?.cancel();
    _hideTimer?.cancel();
    _timeLeft = 0;

    final attempts = _hits + _miss;
    final accuracy = attempts == 0 ? 0.0 : (_hits / attempts) * 100.0;

    // ✅ log เกม
    final chartStore = ChartStore();
    await chartStore.logResult(
      game: 'catpaw',
      difficulty: widget.difficulty.name,
      accuracyPercent: accuracy,
      hits: _hits,
      miss: _miss,
    );

    // ✅ เพิ่ม XP ทุกครั้งที่เล่นจบ (+10)
    await CatBondStore().addXp(amount: 10, source: 'game_finish_catpaw');

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CatPawResultPage(
          difficulty: widget.difficulty,
          hits: _hits,
          miss: _miss,
          pawShow: _hits,
          totalPaw: _totalPaw,
          accuracyPercent: accuracy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // UI sizing for elderly
    return Scaffold(
      body: Stack(
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
                final h = c.maxHeight;

                final bool wide = w >= 900;
                final double topPad = wide ? 16 : 14;

                final double statBoxW = (w * 0.22).clamp(160.0, 260.0);
                final double statBoxH = (h * 0.12).clamp(90.0, 130.0);

                final double boardH = (h * 0.68).clamp(420.0, 760.0);

                final titleSize = (w / 20).clamp(26.0, 42.0);

                return Column(
                  children: [
                    SizedBox(height: topPad),

                    // TOP STATS ROW (HITS / MISS / TIME)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatBox(
                            width: statBoxW,
                            height: statBoxH,
                            title: "",
                            value: _hits.toString(),
                            valueColor: const Color(0xFF7ED957),
                          ),
                          _StatBox(
                            width: statBoxW,
                            height: statBoxH,
                            title: "",
                            value: _miss.toString(),
                            valueColor: const Color(0xFFEF5A5A),
                          ),
                          _TimeBox(
                            width: (statBoxW * 0.70).clamp(120.0, 190.0),
                            height: statBoxH,
                            seconds: _timeLeft,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Big board
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                        child: Container(
                          height: boardH,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: const Color(0xFFFF9800),
                              width: 8,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 20,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, bc) {
                              final bw = bc.maxWidth;
                              final bh = bc.maxHeight;

                              // paw size BIG
                              final pawSize = min(
                                bw * 0.18,
                                120.0,
                              ).clamp(90.0, 140.0);

                              Offset clampToBoard(Offset n) {
                                final margin = 18.0;
                                final x = (n.dx * bw).clamp(
                                  margin,
                                  bw - margin,
                                );
                                final y = (n.dy * bh).clamp(
                                  margin,
                                  bh - margin,
                                );
                                return Offset(x, y);
                              }

                              return Stack(
                                children: [
                                  // optional title inside board (subtle)
                                  Positioned(
                                    top: 14,
                                    left: 16,
                                    child: Text(
                                      AppText.get('tapPaw'),
                                      style: TextStyle(
                                        fontSize: (titleSize * 0.55).clamp(
                                          14.0,
                                          20.0,
                                        ),
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),

                                  // Cells
                                  for (int i = 0; i < _cells.length; i++)
                                    _PawCell(
                                      center: clampToBoard(_cells[i]),
                                      size: pawSize,
                                      isActive: _showing && i == _activeIndex,
                                      onTap: () => _tapCell(i),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final double width;
  final double height;
  final String title;
  final String value;
  final Color valueColor;

  const _StatBox({
    required this.width,
    required this.height,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height + 10,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF9800), width: 6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 0,
              fontWeight: FontWeight.w900,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 0),
          Text(
            value,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final double width;
  final double height;
  final int seconds;

  const _TimeBox({
    required this.width,
    required this.height,
    required this.seconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF9800), width: 6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        "${seconds}s",
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _PawCell extends StatelessWidget {
  final Offset center;
  final double size;
  final bool isActive;
  final VoidCallback onTap;

  const _PawCell({
    required this.center,
    required this.size,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onAsset = "assets/catpaw/paw_on.png";
    final offAsset = "assets/catpaw/paw_off.png";

    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFFFD08A) : Colors.transparent,
          ),
          child: Center(
            child: Image.asset(
              isActive ? onAsset : offAsset,
              width: size * 0.80,
              height: size * 0.80,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.pets,
                size: size * 0.60,
                color: isActive ? const Color(0xFFFF9800) : Colors.black45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
