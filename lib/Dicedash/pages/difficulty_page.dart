import 'package:flutter/material.dart';
import '../models.dart';
import '../theme/dicedash_theme.dart';
import '../widgets/dicedash_bg.dart';
import 'game_page.dart';

class DifficultyPage extends StatelessWidget {
  const DifficultyPage({super.key});

  void _go(BuildContext context, Difficulty d) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GamePage(difficulty: d)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DiceDashBG(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final wide = w >= 900;

              final double headerH = (c.maxHeight * 0.18).clamp(120.0, 190.0);
              final double titleSize = (w / 18).clamp(34.0, 64.0);

              final double cardW = wide
                  ? (w * 0.27).clamp(300.0, 460.0)
                  : (w * 0.86).clamp(320.0, 680.0);

              final double cardH = wide
                  ? (c.maxHeight * 0.62).clamp(420.0, 740.0)
                  : (c.maxHeight * 0.26).clamp(260.0, 360.0);

              final double labelSize = (w / 22).clamp(28.0, 52.0);

              Widget diffCard({
                required String label,
                required String imageAsset,
                required VoidCallback onTap,
              }) {
                final imgBox = wide ? cardW * 0.72 : cardH * 0.82;

                return InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(34),
                  child: Container(
                    width: cardW,
                    height: cardH,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(color: kDiceDashOrange, width: 7),
                      boxShadow: [
                        BoxShadow(
                          color: alphaColor(Colors.black, 0.12),
                          blurRadius: 22,
                          offset: const Offset(0, 14),
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
                                    size: 120,
                                    color: Colors.black26,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: labelSize,
                                  fontWeight: FontWeight.w900,
                                  color: kDiceDashOrange,
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
                                    size: 96,
                                    color: Colors.black26,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 22),
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: labelSize,
                                    fontWeight: FontWeight.w900,
                                    color: kDiceDashOrange,
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
                  const SizedBox(height: 30),

                  // Header Capsule (เหมือนภาพ)
                  SizedBox(
                    height: headerH,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 46,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: kDiceDashOrange,
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [
                            BoxShadow(
                              color: alphaColor(Colors.black, 0.10),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Text(
                          'Calculating Game',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  Expanded(
                    child: Center(
                      child: wide
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                diffCard(
                                  label: 'Easy',
                                  imageAsset: 'assets/difficulty/easy.png',
                                  onTap: () => _go(context, Difficulty.easy),
                                ),
                                const SizedBox(width: 52),
                                diffCard(
                                  label: 'Normal',
                                  imageAsset: 'assets/difficulty/normal.png',
                                  onTap: () => _go(context, Difficulty.normal),
                                ),
                                const SizedBox(width: 52),
                                diffCard(
                                  label: 'Hard',
                                  imageAsset: 'assets/difficulty/hard.png',
                                  onTap: () => _go(context, Difficulty.hard),
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
                                    label: 'Easy',
                                    imageAsset: 'assets/difficulty/easy.png',
                                    onTap: () => _go(context, Difficulty.easy),
                                  ),
                                  const SizedBox(height: 22),
                                  diffCard(
                                    label: 'Normal',
                                    imageAsset: 'assets/difficulty/normal.png',
                                    onTap: () => _go(context, Difficulty.normal),
                                  ),
                                  const SizedBox(height: 22),
                                  diffCard(
                                    label: 'Hard',
                                    imageAsset: 'assets/difficulty/hard.png',
                                    onTap: () => _go(context, Difficulty.hard),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Back Button (ใหญ่ / ผู้สูงวัย)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
