import 'package:flutter/material.dart';
import 'cat_paw_game_page.dart';

enum CatPawDifficulty { easy, normal, hard }

class CatPawDifficultyScreen extends StatelessWidget {
  const CatPawDifficultyScreen({super.key});

  void _go(BuildContext context, CatPawDifficulty d) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CatPawGamePage(difficulty: d)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BG
          Positioned.fill(
            child: Image.asset(
              "assets/bg/catpaw_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFFFFF7F0)),
            ),
          ),
          Positioned.fill(child: Container(color: Colors.white.withValues(alpha: 0.12))),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;

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

                final double headerH = (h * 0.16).clamp(120.0, 180.0);

                final double cardW = wide
                    ? (w * cardWFactorWide).clamp(300.0, 460.0)
                    : (w * cardWFactorNarrow).clamp(320.0, 680.0);

                final double cardH = wide
                    ? (h * cardHFactorWide).clamp(420.0, 700.0)
                    : (h * cardHFactorNarrow).clamp(260.0, 360.0);

                final double titleSize = (w / 20).clamp(34.0, 58.0);
                final double cardLabel = (w / 28).clamp(26.0, 48.0);

                Widget diffCard({
                  required String label,
                  required String imageAsset,
                  required VoidCallback onTap,
                }) {
                  final double imgBox = wide ? cardW * imgScaleWide : cardH * imgScaleNarrow;

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
                        border: Border.all(color: const Color(0xFFFF9800), width: 8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 22,
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
                                  child: Image.asset(
                                    imageAsset,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.pets,
                                      size: 110,
                                      color: Colors.black26,
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
                                  child: Image.asset(
                                    imageAsset,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.pets,
                                      size: 92,
                                      color: Colors.black26,
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

                    // Header like image
                    SizedBox(
                      height: headerH,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800),
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 18,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Text(
                            "Reaction Time Game",
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
                                    label: "Easy",
                                    imageAsset: "assets/difficulty/easy.png",
                                    onTap: () => _go(context, CatPawDifficulty.easy),
                                  ),
                                  SizedBox(width: gapBetweenCardsWide),
                                  diffCard(
                                    label: "Normal",
                                    imageAsset: "assets/difficulty/normal.png",
                                    onTap: () => _go(context, CatPawDifficulty.normal),
                                  ),
                                  SizedBox(width: gapBetweenCardsWide),
                                  diffCard(
                                    label: "Hard",
                                    imageAsset: "assets/difficulty/hard.png",
                                    onTap: () => _go(context, CatPawDifficulty.hard),
                                  ),
                                ],
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Column(
                                  children: [
                                    diffCard(
                                      label: "Easy",
                                      imageAsset: "assets/difficulty/easy.png",
                                      onTap: () => _go(context, CatPawDifficulty.easy),
                                    ),
                                    SizedBox(height: gapBetweenCardsNarrow),
                                    diffCard(
                                      label: "Normal",
                                      imageAsset: "assets/difficulty/normal.png",
                                      onTap: () => _go(context, CatPawDifficulty.normal),
                                    ),
                                    SizedBox(height: gapBetweenCardsNarrow),
                                    diffCard(
                                      label: "Hard",
                                      imageAsset: "assets/difficulty/hard.png",
                                      onTap: () => _go(context, CatPawDifficulty.hard),
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
    );
  }
}
