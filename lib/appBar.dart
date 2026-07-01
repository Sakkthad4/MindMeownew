import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../audio/bgm.dart'; // <- ปรับ path ให้ถูก เช่น 'package:flutter_test22/audio/bgm.dart'

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 100,
      leading: Padding(
        padding: const EdgeInsets.only(left: 23),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 44, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      flexibleSpace: SafeArea(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 100),
            child: Text(
              "Marie H. Smith",
              style: GoogleFonts.montserrat(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      actions: [
        // ✅ ปุ่มเปิด/ปิดเสียงแทน auto_graph
        ValueListenableBuilder<bool>(
          valueListenable: Bgm.instance.muted,
          builder: (_, isMuted, __) {
            return IconButton(
              icon: Icon(
                isMuted ? Icons.music_off : Icons.music_note, // หรือ volume_off / volume_up
                size: 70,
                color: Colors.white,
              ),
              onPressed: () async {
                await Bgm.instance.toggleMute();
              },
            );
          },
        ),

        Padding(
          padding: const EdgeInsets.only(right: 25),
          child: IconButton(
            icon: const Icon(Icons.settings, size: 70),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
