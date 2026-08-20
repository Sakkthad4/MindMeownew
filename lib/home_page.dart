/*import 'package:flutter/material.dart';
import 'appBar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(), // ← ใช้ชื่อคลาสใหม่
      body: Column(
        children: [
          Container(),
          //
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // กระจายให้ห่างกันเท่าๆ กัน
              children: [
                ElevatedButton(
                  onPressed: () {
                    //Navigator.pushNamed(context, '/calendar');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 45, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      // side: BorderSide(color: Colors.black, width: 2),
                    ),
                    elevation: 0, // ไม่มีเงา
                  ),
                  child: Image.asset('//'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'appBar.dart';
import 'Myfuncbox.dart';
import 'package:intl/intl.dart';
import 'app_language.dart';
import 'audio/page_voice.dart';

String currentTime = DateFormat('HH:mm').format(DateTime.now());

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.playGreeting = false});

  final bool playGreeting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),
      body: PageVoice(
        assetPath: VoiceAssets.hello,
        enabled: playGreeting,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 40, // ซ้าย + ขวา
                vertical: 40, // บน + ล่าง
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // กระจายให้ห่างกันเท่าๆ กัน
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/calendar');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple.shade200,
                      fixedSize: Size(720, 275),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                        side: BorderSide(
                          color: Colors.purple.shade200,
                          width: 12,
                        ),
                      ),
                      elevation: 0, // ไม่มีเงา
                    ),
                    child: Text(
                      currentTime,
                      style: GoogleFonts.montserrat(
                        fontSize: 180,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  MyFuncBox(
                    AppText.get('exercises'),
                    '/stretch',
                    'assets/images/MindMeowfunc_icon1.png',
                    const Color.fromARGB(255, 92, 225, 230),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 40, // ซ้าย + ขวา
                vertical: 0, // บน + ล่าง
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // กระจายให้ห่างกันเท่าๆ กัน
                children: [
                  MyFuncBox(
                    AppText.get('games'),
                    '/games',
                    'assets/images/MindMeowfunc_icon2.png',
                    const Color.fromARGB(255, 126, 158, 255),
                  ),
                  MyFuncBox(
                    AppText.get('mindTalk'),
                    '/geminiloop',
                    'assets/images/MindMeowfunc_icon3.png',
                    const Color.fromARGB(255, 253, 155, 36),
                  ),
                  MyFuncBox(
                    AppText.get('healthCare'),
                    '/healthcare',
                    'assets/images/MindMeowfunc_icon4.png',
                    const Color.fromARGB(255, 230, 87, 87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
