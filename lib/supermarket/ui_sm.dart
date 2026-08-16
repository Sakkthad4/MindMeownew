import 'package:flutter/material.dart';

class SM {
  static const bg = Color(0xFFF7F7F7);
  static const orange = Color(0xFFFF9800);
  static const orangeDark = Color(0xFFF57C00);

  static const softOrange = Color(0xFFFFD0A6);

  static const borderOrange = Color(0xFFFF9800);
  static const cartBlue = Color(0xFF77C9FF);

  static TextStyle title(BuildContext c) => TextStyle(
    fontSize: 46 * scale(c),
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  static TextStyle h1(BuildContext c) => TextStyle(
    fontSize: 42 * scale(c),
    fontWeight: FontWeight.w900,
    color: orange,
  );

  static TextStyle h2(BuildContext c) => TextStyle(
    fontSize: 34 * scale(c),
    fontWeight: FontWeight.w900,
    color: orange,
  );

  static TextStyle body(BuildContext c) => TextStyle(
    fontSize: 26 * scale(c),
    fontWeight: FontWeight.w800,
    color: Colors.black87,
  );

  static TextStyle bodySoft(BuildContext c) => TextStyle(
    fontSize: 24 * scale(c),
    fontWeight: FontWeight.w800,
    color: Colors.black54,
  );

  static double scale(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    return (w / 1200.0).clamp(0.85, 1.25);
  }

  static BoxDecoration orangeFrame({double r = 30}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(r),
    border: Border.all(color: borderOrange, width: 6),
  );

  static BoxDecoration softCard({double r = 30}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(r),
    boxShadow: const [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
  );

  static Widget bgPattern({required Widget child}) {
    // Placeholder background (you will replace with Image.asset later)
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF7F7F7)),
      child: child,
    );
  }

  static Widget orangeHeaderPill(BuildContext c, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
      decoration: BoxDecoration(
        color: orange,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: orangeDark, width: 5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 44 * scale(c),
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  static ButtonStyle bigOrangeBtn(BuildContext c) => ElevatedButton.styleFrom(
    backgroundColor: orange,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    textStyle: TextStyle(fontSize: 40 * scale(c), fontWeight: FontWeight.w900),
  );
}
