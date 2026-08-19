import 'package:flutter/material.dart';
import 'package:flutter_test22/appBar.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_language.dart';

class GameMenuPage extends StatelessWidget {
  const GameMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 28.0;
            final gridWidth = constraints.maxWidth > 1320
                ? 1320.0
                : constraints.maxWidth;
            final gridHeight = constraints.maxHeight > 560
                ? 560.0
                : constraints.maxHeight;
            final cardWidth = (gridWidth - gap) / 2;
            final cardHeight = (gridHeight - gap) / 2;

            final games = [
              (
                title: AppText.get('supermarket'),
                image: 'assets/images/MindMeowgamesSupermarket.png',
                route: '/supermarket',
              ),
              (
                title: AppText.get('diceDash'),
                image: 'assets/images/MindMeowgamesDice.png',
                route: '/dicedash',
              ),
              (
                title: AppText.get('catPaw'),
                image: 'assets/images/MindMeowgamesPaws.png',
                route: '/catpaw',
              ),
              (
                title: AppText.get('draw'),
                image: 'assets/images/MindMeowgamesDraw.png',
                route: '/drawvis',
              ),
            ];

            return Center(
              child: SizedBox(
                width: gridWidth,
                height: gridHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: games.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                    childAspectRatio: cardWidth / cardHeight,
                  ),
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return GameBox(game.title, game.image, game.route);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class GameBox extends StatelessWidget {
  const GameBox(this.title, this.imagePath, this.gamesgo, {super.key});

  final String title;
  final String imagePath;
  final String gamesgo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, gamesgo),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.orange, width: 6),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final iconSize = (constraints.maxHeight * 0.92).clamp(
                96.0,
                230.0,
              );
              final fontSize = (constraints.maxWidth / 10.5).clamp(32.0, 60.0);

              return Row(
                children: [
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: Image.asset(imagePath, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: GoogleFonts.montserrat(
                          color: Colors.orange,
                          fontSize: fontSize,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
