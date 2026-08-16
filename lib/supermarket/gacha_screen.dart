import 'dart:math';
import 'package:flutter/material.dart';
import '../app_language.dart';

import 'data.dart';
import 'models.dart';
import 'order_brief_screen.dart';
import 'ui_sm.dart';

import '../audio/soundeffect.dart';

class GachaScreen extends StatefulWidget {
  final Difficulty difficulty;

  const GachaScreen({super.key, required this.difficulty});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  final _rng = Random();
  RecipeTemplate? _current;
  bool _rolling = false;

  // ✅ Hero tag ที่จะส่งไปหน้า OrderBrief (ต้องเหมือนกันทั้ง 2 หน้า)
  String _heroTag = "plate_default";

  @override
  void initState() {
    super.initState();
    if (recipeTemplates.isNotEmpty) {
      _current = recipeTemplates.first;
      _heroTag = "plate_${_current!.id}_init";
    }
  }

  int _ingredientKinds() {
    switch (widget.difficulty) {
      case Difficulty.easy:
        return 4;
      case Difficulty.normal:
        return 6;
      case Difficulty.hard:
        return 8;
    }
  }

  int _maxQty() {
    switch (widget.difficulty) {
      case Difficulty.easy:
        return 5;
      case Difficulty.normal:
        return 5;
      case Difficulty.hard:
        return 6;
    }
  }

  Order _buildOrder(RecipeTemplate t) {
    final kinds = _ingredientKinds();
    final maxQty = _maxQty();

    final ids = <String>[...t.ingredientIds];

    if (ids.length < kinds) {
      final pool = ingredients.map((e) => e.id).toList()..shuffle(_rng);
      for (final id in pool) {
        if (ids.length >= kinds) break;
        if (!ids.contains(id)) ids.add(id);
      }
    }

    ids.shuffle(_rng);
    final picked = ids.take(kinds);

    final req = <String, int>{};
    for (final id in picked) {
      req[id] = 1 + _rng.nextInt(maxQty);
    }

    return Order(
      id: t.id,
      name: t.name,
      plateAsset: t.plateAsset,
      requiredQty: req,
    );
  }

  Future<void> _roll(BuildContext context) async {
    if (_rolling) return;
    setState(() => _rolling = true);

    RecipeTemplate finalPick = recipeTemplates.first;

    for (int i = 0; i < 14; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      setState(() {
        finalPick = recipeTemplates[_rng.nextInt(recipeTemplates.length)];
        _current = finalPick;
      });
    }

    setState(() => _rolling = false);

    _heroTag = "plate_${finalPick.id}_${DateTime.now().microsecondsSinceEpoch}";

    final order = _buildOrder(finalPick);

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderBriefScreen(
          order: order,
          difficulty: widget.difficulty,
          heroTag: _heroTag,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = SM.scale(context);

    return Scaffold(
      body: Stack(
        children: [
          // ✅ BG รูปอยู่ "ล่างสุด"
          Positioned.fill(
            child: Image.asset(
              "assets/bg/supermarketbg.png",
              fit: BoxFit.cover,
            ),
          ),

          // ✅ ของเดิม: bgPattern + UI
          SM.bgPattern(
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ===== Menu Card =====
                    Container(
                      width: 520,
                      height: 420,
                      decoration: SM.orangeFrame(r: 34),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _current == null
                                ? const Icon(
                                    Icons.restaurant,
                                    size: 120,
                                    color: Colors.black26,
                                  )
                                : Hero(
                                    tag: _heroTag,
                                    child: Image.asset(
                                      _current!.plateAsset,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.image_not_supported,
                                        size: 120,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: SM.softOrange,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              _current == null
                                  ? AppText.get('menu')
                                  : AppText.name(_current!.name),
                              style: TextStyle(
                                fontSize: 30 * scale,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ===== Roll Button =====
                    SizedBox(
                      width: 300,
                      height: 76,
                      child: ElevatedButton.icon(
                        style: SM.bigOrangeBtn(context),
                        icon: const Icon(Icons.casino, size: 25),
                        label: Text(
                          _rolling
                              ? AppText.get('rolling')
                              : AppText.get('roll'),
                          style: TextStyle(
                            fontSize: 30 * scale,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        onPressed: _rolling
                            ? null
                            : () {
                                SoundFx.play(
                                  SoundFx.hungry,
                                  volume: SoundFx.hungryVolume,
                                );

                                _roll(context);
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
