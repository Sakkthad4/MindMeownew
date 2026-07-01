import 'package:flutter/material.dart';
import '../theme/dicedash_theme.dart';

class ChoiceTile extends StatelessWidget {
  final int value;
  final double height;
  final bool locked;
  final bool selected;
  final int correct;
  final VoidCallback onTap;

  const ChoiceTile({
    super.key,
    required this.value,
    required this.height,
    required this.locked,
    required this.selected,
    required this.correct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = value == correct;

    Color border = kDiceDashOrange;
    Color bg = Colors.white;

    // ตอนตอบแล้ว: กรอบเขียว/แดงแบบชัดๆ
    if (locked && selected) {
      border = isCorrect ? Colors.green : Colors.red;
      bg = alphaColor(border, 0.10);
    }

    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: border, width: 7),
          boxShadow: [
            BoxShadow(
              color: alphaColor(Colors.black, 0.10),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
