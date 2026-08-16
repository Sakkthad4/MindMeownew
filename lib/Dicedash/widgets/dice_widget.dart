import 'package:flutter/material.dart';
import '../theme/dicedash_theme.dart';

class DiceFace extends StatelessWidget {
  final int value;
  final double size;

  const DiceFace({super.key, required this.value, this.size = 110});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(1, 6);
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange, width: 5),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 14),
            color: alphaColor(Colors.black, 0.12),
          ),
        ],
      ),
      child: Stack(children: _pipsFor(v)),
    );
  }

  List<Widget> _pipsFor(int v) {
    const tl = Offset(0.25, 0.25);
    const tr = Offset(0.75, 0.25);
    const bl = Offset(0.25, 0.75);
    const br = Offset(0.75, 0.75);
    const ml = Offset(0.25, 0.50);
    const mr = Offset(0.75, 0.50);
    const c = Offset(0.50, 0.50);

    List<Offset> pos;
    switch (v) {
      case 1:
        pos = [c];
        break;
      case 2:
        pos = [tl, br];
        break;
      case 3:
        pos = [tl, c, br];
        break;
      case 4:
        pos = [tl, tr, bl, br];
        break;
      case 5:
        pos = [tl, tr, c, bl, br];
        break;
      case 6:
        pos = [tl, tr, ml, mr, bl, br];
        break;
      default:
        pos = [c];
    }

    return pos.map((p) => _pip(p)).toList();
  }

  Widget _pip(Offset frac) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment(frac.dx * 2 - 1, frac.dy * 2 - 1),
        child: Container(
          width: size * 0.16,
          height: size * 0.16,
          decoration: BoxDecoration(
            color: alphaColor(Colors.black, 0.90),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                offset: const Offset(0, 3),
                color: alphaColor(Colors.black, 0.18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
