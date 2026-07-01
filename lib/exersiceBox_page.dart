import 'package:flutter/material.dart';
import 'package:flutter_test22/appBar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class ExersiceMenuPage extends StatelessWidget {
  const ExersiceMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 25, top: 20, bottom: 16),
        child: Scrollbar(
          thumbVisibility: true,
          thickness: 8,
          radius: const Radius.circular(10),
          child: ListView(
            padding: const EdgeInsets.only(
              right: 20,
            ), // 👈 ย้าย padding ขวาเข้ามาใน ListView
            children: [
              ExersiceBox(
                "Morning Stretch",
                'assets/images/MindMeowexersicesStretch.png',
                '/stretch',
              ),
              ExersiceBox(
                "Dance",
                'assets/images/MindMeowexersicesDance.png',
                '/start',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExersiceBox extends StatelessWidget {
  final String title;
  final String imagePath;
  final String gamesgo;

  const ExersiceBox(this.title, this.imagePath, this.gamesgo, {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        print("Tapped $title → going to $gamesgo");
        Navigator.pushNamed(context, gamesgo);
      },

      child: Align(
        alignment: Alignment.centerLeft, // 👈 ชิดซ้าย
        child: SizedBox(
          width: 725, // 👈 ปรับความยาวกล่องตรงนี้ตามใจ
          height: 150,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange, width: 4),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.orange,
                      fontSize: 60,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
