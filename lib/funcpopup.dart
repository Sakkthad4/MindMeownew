import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FuncPopup extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onGo;
  final VoidCallback onCancel;

  const FuncPopup({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onGo,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.orange, width: 8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imagePath, width: 350),
            const SizedBox(height: 20),

            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 76,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7A8BFF),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ✅ GO
                InkWell(
                  onTap: onGo, // ❌ ไม่ pop ที่นี่แล้ว
                  child: _btn("GO!", Colors.orange),
                ),

                // ✅ CANCEL
                InkWell(
                  onTap: onCancel, // ❌ ไม่ pop ที่นี่แล้ว
                  child: _btn("Cancel", Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 44,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

void showFuncPopup(
  BuildContext context, {
  required String title,
  required String imagePath,
  required VoidCallback onGo,
  required VoidCallback onCancel,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return FuncPopup(
        title: title,
        imagePath: imagePath,
        onGo: onGo,
        onCancel: onCancel,
      );
    },
  );
}
