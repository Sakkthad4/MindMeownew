import 'package:flutter/material.dart';
import '../audio/bgm_scope.dart';
import 'game_page.dart';
import '../app_language.dart';

enum DrawingDifficulty { easy, normal, hard }

class DrawingDifficultyPage extends StatelessWidget {
  const DrawingDifficultyPage({super.key});

  void _go(BuildContext context, DrawingDifficulty d) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DrawingGamePage(difficulty: d)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BgmScope(
      assetPath: 'audio/bgm_supermarket.mp3', // เปลี่ยนเป็น bgm_drawing.mp3 ได้
      child: Scaffold(
        body: Stack(
          children: [
            // BG (เปลี่ยน path ให้ตรง asset ของคุณ)
            Positioned.fill(
              child: Image.asset("assets/bg/drawitbg.png", fit: BoxFit.cover),
            ),
            // overlay จาง
            Positioned.fill(
              child: Container(color: Colors.white.withValues(alpha: 0.12)),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final h = c.maxHeight;

                  // -----------------------------
                  // ✅ CONTROL PANEL (เหมือนของคุณ)
                  // -----------------------------
                  final bool wide = w >= 900;

                  final double topGap = wide ? 12 : 10;
                  final double gapHeaderToCards = wide ? 22 : 18;

                  final double gapBetweenCardsWide = wide ? 48 : 0;
                  final double gapBetweenCardsNarrow = 20;

                  final double cardWFactorWide = 0.28;
                  final double cardHFactorWide = 0.62;
                  final double cardWFactorNarrow = 0.86;
                  final double cardHFactorNarrow = 0.25;

                  final double imgScaleWide = 0.75;
                  final double imgScaleNarrow = 0.85;

                  final double imgPadding = 6;
                  // -----------------------------

                  final double headerH = (h * 0.16).clamp(120.0, 180.0);

                  final double cardW = wide
                      ? (w * cardWFactorWide).clamp(300.0, 440.0)
                      : (w * cardWFactorNarrow).clamp(320.0, 640.0);

                  final double cardH = wide
                      ? (h * cardHFactorWide).clamp(420.0, 680.0)
                      : (h * cardHFactorNarrow).clamp(260.0, 340.0);

                  final double titleSize = (w / 22).clamp(32.0, 56.0);
                  final double cardLabel = (w / 30).clamp(26.0, 46.0);

                  Widget diffCard({
                    required String label,
                    required String imageAsset,
                    required VoidCallback onTap,
                  }) {
                    final double imgBox = wide
                        ? cardW * imgScaleWide
                        : cardH * imgScaleNarrow;

                    return InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: cardW,
                        height: cardH,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFFF9800),
                            width: 6,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 20,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: wide
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: imgBox,
                                    height: imgBox,
                                    child: Padding(
                                      padding: EdgeInsets.all(imgPadding),
                                      child: Image.asset(
                                        imageAsset,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.pets,
                                              size: 96,
                                              color: Colors.black26,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: cardLabel,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFFF9800),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  SizedBox(
                                    width: imgBox,
                                    height: imgBox,
                                    child: Padding(
                                      padding: EdgeInsets.all(imgPadding),
                                      child: Image.asset(
                                        imageAsset,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.pets,
                                              size: 80,
                                              color: Colors.black26,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 22),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: cardLabel,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFFFF9800),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      SizedBox(height: topGap),

                      // Header pill
                      SizedBox(
                        height: headerH,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFFF57C00),
                                width: 0,
                              ),
                            ),
                            child: Text(
                              AppText.get('drawingGame'),
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: gapHeaderToCards),

                      Expanded(
                        child: Center(
                          child: wide
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    diffCard(
                                      label: AppText.get('easy'),
                                      // ใช้รูปแมวแบบที่คุณส่ง
                                      imageAsset: "assets/difficulty/easy.png",
                                      onTap: () =>
                                          _go(context, DrawingDifficulty.easy),
                                    ),
                                    SizedBox(width: gapBetweenCardsWide),
                                    diffCard(
                                      label: AppText.get('normal'),
                                      imageAsset:
                                          "assets/difficulty/normal.png",
                                      onTap: () => _go(
                                        context,
                                        DrawingDifficulty.normal,
                                      ),
                                    ),
                                    SizedBox(width: gapBetweenCardsWide),
                                    diffCard(
                                      label: AppText.get('hard'),
                                      imageAsset: "assets/difficulty/hard.png",
                                      onTap: () =>
                                          _go(context, DrawingDifficulty.hard),
                                    ),
                                  ],
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    children: [
                                      diffCard(
                                        label: AppText.get('easy'),
                                        imageAsset:
                                            "assets/difficulty/easy.png",
                                        onTap: () => _go(
                                          context,
                                          DrawingDifficulty.easy,
                                        ),
                                      ),
                                      SizedBox(height: gapBetweenCardsNarrow),
                                      diffCard(
                                        label: AppText.get('normal'),
                                        imageAsset:
                                            "assets/difficulty/normal.png",
                                        onTap: () => _go(
                                          context,
                                          DrawingDifficulty.normal,
                                        ),
                                      ),
                                      SizedBox(height: gapBetweenCardsNarrow),
                                      diffCard(
                                        label: AppText.get('hard'),
                                        imageAsset:
                                            "assets/difficulty/hard.png",
                                        onTap: () => _go(
                                          context,
                                          DrawingDifficulty.hard,
                                        ),
                                      ),
                                    ],
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
      ),
    );
  }
}
