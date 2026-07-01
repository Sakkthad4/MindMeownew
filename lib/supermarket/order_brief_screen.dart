import 'dart:async';
import 'package:flutter/material.dart';

import 'data.dart';
import 'models.dart';
import 'ingredient_select_screen.dart';

class OrderBriefScreen extends StatefulWidget {
  final Order order;
  final Difficulty difficulty;

  // ✅ เพิ่มสำหรับ Hero transition
  final String heroTag;

  const OrderBriefScreen({
    super.key,
    required this.order,
    required this.difficulty,
    required this.heroTag,
  });

  @override
  State<OrderBriefScreen> createState() => _OrderBriefScreenState();
}

class _OrderBriefScreenState extends State<OrderBriefScreen> {
  late int _secondsLeft;
  Timer? _timer;

  int _secondsByDifficulty() {
    switch (widget.difficulty) {
      case Difficulty.easy:
        return 40;
      case Difficulty.normal:
        return 30;
      case Difficulty.hard:
        return 30;
    }
  }

  @override
  void initState() {
    super.initState();
    _secondsLeft = _secondsByDifficulty();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);

      if (_secondsLeft <= 0) {
        t.cancel();
        _goShop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goShop() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => IngredientSelectScreen(
          order: widget.order,
          difficulty: widget.difficulty,
        ),
      ),
    );
  }

  String _difficultyLabel() {
    switch (widget.difficulty) {
      case Difficulty.easy:
        return "Easy";
      case Difficulty.normal:
        return "Normal";
      case Difficulty.hard:
        return "Hard";
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.order.requiredQty.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      body: Stack(
        children: [
          // ✅ Background image (ของเดิมคุณ)
          Positioned.fill(
            child: Image.asset(
              "assets/bg/supermarketbg.png",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.10)),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;
                final wide = w >= 900;

                final double outerPad = (w * 0.03).clamp(14.0, 28.0);
                final double gap = (w * 0.02).clamp(14.0, 26.0);

                final double leftW = (wide ? w * 0.36 : w * 0.92).clamp(
                  340.0,
                  560.0,
                );
                final double rightW = (wide ? w * 0.56 : w * 0.92).clamp(
                  420.0,
                  980.0,
                );

                final double dishTitle = (w / 26).clamp(22.0, 32.0);
                final double headerText = (w / 24).clamp(26.0, 40.0);
                final double rowName = (w / 30).clamp(22.0, 30.0);
                final double qtyText = (w / 34).clamp(20.0, 28.0);

                const orange = Color(0xFFFF9800);
                const orangeDark = Color(0xFFF57C00);

                Widget leftPanel() {
                  return Column(
                    children: [
                      Container(
                        width: leftW,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: orange, width: 5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: (wide ? h * 0.22 : h * 0.18).clamp(
                                150.0,
                                260.0,
                              ),
                              child: Hero(
                                tag: widget.heroTag, // ✅ ตรงนี้คือ Hero ปลายทาง
                                child: Image.asset(
                                  widget.order.plateAsset,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_not_supported,
                                    size: 120,
                                    color: Colors.black26,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC58F),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Text(
                                widget.order.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: dishTitle,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Difficulty: ${_difficultyLabel()}",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: (w / 44).clamp(14.0, 18.0),
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        width: leftW,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: orange, width: 5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 14,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "MEMORIZE TIME",
                              style: TextStyle(
                                fontSize: (w / 42).clamp(16.0, 20.0),
                                fontWeight: FontWeight.w900,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "00:${_secondsLeft.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                fontSize: (w / 18).clamp(36.0, 56.0),
                                fontWeight: FontWeight.w900,
                                color: orangeDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _goShop,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: (w / 34).clamp(18.0, 24.0),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                child: const Text("Start Shopping"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                Widget rightPanel() {
                  return Container(
                    width: rightW,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: orange, width: 5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 34,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: orange,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: orangeDark, width: 6),
                          ),
                          child: Text(
                            "requirement",
                            style: TextStyle(
                              fontSize: headerText,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Color(0xFFFFB56D),
                                width: 5,
                              ),
                            ),
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: ListView.separated(
                                itemCount: req.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (context, i) {
                                  final e = req[i];
                                  final ing = ingredientById(e.key);
                                  final qty = e.value;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: orange,
                                        width: 4,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x0F000000),
                                          blurRadius: 10,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 64,
                                          height: 64,
                                          child: Image.asset(
                                            ing.asset,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.image_not_supported,
                                                  size: 40,
                                                  color: Colors.black26,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            ing.name,
                                            style: TextStyle(
                                              fontSize: rowName,
                                              fontWeight: FontWeight.w900,
                                              color: orange,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 82,
                                          height: 64,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: orange,
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: orangeDark,
                                              width: 5,
                                            ),
                                          ),
                                          child: Text(
                                            "x$qty",
                                            style: TextStyle(
                                              fontSize: qtyText,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.all(outerPad),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(width: leftW, child: leftPanel()),
                            SizedBox(width: gap),
                            Expanded(child: rightPanel()),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(width: leftW, child: leftPanel()),
                              SizedBox(height: gap),
                              SizedBox(
                                height: (h * 0.65).clamp(420.0, 720.0),
                                child: rightPanel(),
                              ),
                            ],
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
