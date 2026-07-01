import 'package:flutter/material.dart';
import '../theme/dicedash_theme.dart';

class DiceDashBG extends StatelessWidget {
  final Widget child;
  const DiceDashBG({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/bg/dicedash_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: alphaColor(Colors.white, 0.45), // ให้เหมือนภาพ (ขาว แต่ยังเห็นลาย)
          ),
        ),
        child,
      ],
    );
  }
}
