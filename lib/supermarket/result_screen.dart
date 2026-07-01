import 'package:flutter/material.dart';
import 'package:flutter_test22/chart/chart_store.dart';

import 'data.dart';
import 'models.dart';
import 'ui_sm.dart';
import '../logic/game_logic.dart';

class ResultScreen extends StatefulWidget {
  final Order order;
  final Map<String, int> cart;
  final Difficulty difficulty;

  const ResultScreen({
    super.key,
    required this.order,
    required this.cart,
    required this.difficulty,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _saved = false;
  bool _rewarded = false;

  Future<void> _saveOnce({
    required String game,
    required String difficulty,
    required double accuracyPercent, // ✅ เพิ่ม
    required int hits,
    required int miss,
  }) async {
    if (_saved) return;
    _saved = true;
    try {
      await ChartStore().logResult(
        game: game,
        difficulty: difficulty,
        accuracyPercent: accuracyPercent,
        hits: hits,
        miss: miss,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final required = widget.order.requiredQty;

    // ---- score with EXTRA penalty ----
    int requiredUnits = 0;
    int correctUnits = 0;
    int missingUnits = 0;
    int extraUnits = 0;

    for (final e in required.entries) {
      final id = e.key;
      final req = e.value;
      final got = widget.cart[id] ?? 0;

      requiredUnits += req;
      correctUnits += (got >= req) ? req : got;

      if (got < req) missingUnits += (req - got);
      if (got > req) extraUnits += (got - req);
    }

    for (final e in widget.cart.entries) {
      if (!required.containsKey(e.key)) extraUnits += e.value;
    }

    int scoreUnits = correctUnits - extraUnits;
    if (scoreUnits < 0) scoreUnits = 0;
    if (scoreUnits > requiredUnits) scoreUnits = requiredUnits;

    final accuracy = requiredUnits == 0 ? 0.0 : (scoreUnits / requiredUnits);
    final accuracyPercent = (accuracy * 100.0).clamp(0.0, 100.0);
    final percent = accuracyPercent.round();

    // ✅ rank + color
    final String label = percent >= 80
        ? "Good"
        : percent >= 50
        ? "Okay"
        : "Try Again";

    final Color accColor = percent >= 80
        ? const Color(0xFF7BC043) // green
        : percent >= 50
        ? const Color(0xFFFFB74D) // orange
        : const Color(0xFFE25B5B); // red

    // requirement rows
    final reqList = required.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // collected chips (show everything in cart)
    final collectedIds = widget.cart.keys.toList()..sort();

    // ⭐ WIN CONDITION
    if (!_rewarded && percent >= 80) {
      _rewarded = true;

      // เรียกหลัง frame แรก เพื่อกัน build loop
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onGameWin();
      });
    }

    return Scaffold(
      body: SM.bgPattern(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // LEFT column (menu + accuracy)
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            // menu card
                            Container(
                              height: 320,
                              width: double.infinity,
                              decoration: SM.orangeFrame(r: 34),
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 180,
                                    height: 180,
                                    decoration: const BoxDecoration(
                                      color: Color(0x00000000),
                                    ),
                                    child: Image.asset(
                                      widget.order.plateAsset,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.image_not_supported,
                                        size: 80,
                                        color: Colors.black26,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 34,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SM.softOrange,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      widget.order.name,
                                      style: TextStyle(
                                        fontSize: 30 * SM.scale(context),
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Accuracy card
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: SM.orangeFrame(r: 34),
                                padding: const EdgeInsets.all(22),
                                child: _AccuracyPanel(
                                  acc: accuracyPercent,
                                  rankText: label,
                                  accColor: accColor,
                                  bigNumber: 78 * SM.scale(context),
                                  bigTitle: 34 * SM.scale(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      // RIGHT column (requirements + collected row)
                      Expanded(
                        flex: 8,
                        child: Column(
                          children: [
                            // Requirements panel
                            Expanded(
                              flex: 7,
                              child: Container(
                                decoration: SM.orangeFrame(r: 34),
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  children: [
                                    SM.orangeHeaderPill(context, "Requirement"),
                                    const SizedBox(height: 18),
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: reqList.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 18),
                                        itemBuilder: (_, i) {
                                          final id = reqList[i].key;
                                          final reqQty = reqList[i].value;
                                          final got = widget.cart[id] ?? 0;
                                          final ing = ingredientById(id);

                                          return _ReqLine(
                                            name: ing.name,
                                            asset: ing.asset,
                                            reqQty: reqQty,
                                            gotQty: got,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Collected panel (bottom row)
                            Container(
                              height: 210,
                              decoration: SM.orangeFrame(r: 34),
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: collectedIds.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 18),
                                      itemBuilder: (_, i) {
                                        final id = collectedIds[i];
                                        final qty = widget.cart[id] ?? 0;

                                        final reqQty = required[id] ?? 0;
                                        final status = _chipStatus(
                                          reqQty: reqQty,
                                          gotQty: qty,
                                        );

                                        final ing = ingredientById(id);

                                        return _CollectedChip(
                                          label: ing.name,
                                          asset: ing.asset,
                                          qty: qty,
                                          status: status,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  SizedBox(
                                    width: 260,
                                    child: ElevatedButton(
                                      style: SM.bigOrangeBtn(context),
                                      onPressed: () async {
                                        await _saveOnce(
                                          game: 'supermarket',
                                          difficulty: widget.difficulty.name,
                                          accuracyPercent:
                                              accuracyPercent, // ✅ เพิ่ม (ตัวแปรใน build)
                                          hits: correctUnits,
                                          miss: missingUnits + extraUnits,
                                        );

                                        if (!context.mounted) return;
                                        Navigator.of(
                                          context,
                                        ).pushNamedAndRemoveUntil(
                                          '/home',
                                          (r) => false,
                                        );
                                      },

                                      child: const Text("Home"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ChipStatus _chipStatus({required int reqQty, required int gotQty}) {
    if (reqQty == 0 && gotQty > 0) return _ChipStatus.extra;
    if (gotQty == reqQty) return _ChipStatus.ok;
    if (gotQty < reqQty) return _ChipStatus.missing;
    return _ChipStatus.extra;
  }
}

class _AccuracyPanel extends StatelessWidget {
  final double acc;
  final double bigNumber;
  final double bigTitle;
  final String rankText;
  final Color accColor;

  const _AccuracyPanel({
    required this.acc,
    required this.bigNumber,
    required this.bigTitle,
    required this.rankText,
    required this.accColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final double maxCircle = c.maxWidth < c.maxHeight
            ? c.maxWidth
            : c.maxHeight;

        final double circleSize = (maxCircle * 0.68).clamp(180.0, 280.0);
        final double ringSize = circleSize - 20;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Accuracy",
              style: TextStyle(
                fontSize: (bigTitle * 0.9).clamp(20.0, 34.0),
                fontWeight: FontWeight.w900,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: circleSize,
              height: circleSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: ringSize,
                    height: ringSize,
                    child: CircularProgressIndicator(
                      value: (acc.clamp(0.0, 100.0)) / 100.0,
                      strokeWidth: 22,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: AlwaysStoppedAnimation<Color>(accColor),
                    ),
                  ),
                  Text(
                    "${acc.toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: (circleSize * 0.20).clamp(48.0, 86.0),
                      fontWeight: FontWeight.w900,
                      color: accColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 0),
            Text(
              rankText,
              style: TextStyle(
                fontSize: (bigTitle * 1.1).clamp(26.0, 44.0),
                fontWeight: FontWeight.w900,
                color: accColor,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReqLine extends StatelessWidget {
  final String name;
  final String asset;
  final int reqQty;
  final int gotQty;

  const _ReqLine({
    required this.name,
    required this.asset,
    required this.reqQty,
    required this.gotQty,
  });

  @override
  Widget build(BuildContext context) {
    final ok = gotQty == reqQty;
    final missing = gotQty < reqQty;

    final Color leftBg = ok
        ? const Color(0xFFE8F7EE)
        : missing
        ? const Color(0xFFFFF3E8)
        : const Color(0xFFFFE8E8);

    final Color border = ok
        ? const Color(0xFF7BC043)
        : missing
        ? const Color(0xFFFFB74D)
        : const Color(0xFFE25B5B);

    final String badgeText = ok
        ? "OK"
        : missing
        ? "Missing"
        : "Extra";

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: leftBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: border, width: 5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.image_not_supported,
                size: 40,
                color: Colors.black26,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 38 * SM.scale(context),
                fontWeight: FontWeight.w900,
                color: SM.orange,
              ),
            ),
          ),
          Container(
            width: 120,
            height: 86,
            decoration: BoxDecoration(
              color: SM.orange,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: SM.orangeDark, width: 5),
            ),
            alignment: Alignment.center,
            child: Text(
              "x$reqQty",
              style: TextStyle(
                fontSize: 38 * SM.scale(context),
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border, width: 4),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 22 * SM.scale(context),
                fontWeight: FontWeight.w900,
                color: border,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ChipStatus { ok, missing, extra }

class _CollectedChip extends StatelessWidget {
  final String label;
  final String asset;
  final int qty;
  final _ChipStatus status;

  const _CollectedChip({
    required this.label,
    required this.asset,
    required this.qty,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    if (status == _ChipStatus.ok) {
      bg = const Color(0xFF7BC043);
      border = const Color(0xFF4E8F22);
    } else if (status == _ChipStatus.missing) {
      bg = const Color(0xFFEDC048);
      border = const Color(0xFFB98A00);
    } else {
      bg = const Color(0xFFE25B5B);
      border = const Color(0xFFB53B3B);
    }

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: bg.withOpacity(0.18),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: border, width: 6),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: bg.withOpacity(0.35),
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported,
                  size: 56,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: 4),
              ),
              alignment: Alignment.center,
              child: Text(
                "$qty",
                style: TextStyle(
                  fontSize: 26 * SM.scale(context),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
