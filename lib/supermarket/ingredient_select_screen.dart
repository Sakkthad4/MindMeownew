import 'package:flutter/material.dart';
import '../app_language.dart';
import 'data.dart';
import 'models.dart';
import 'result_screen.dart';
import '../audio/soundeffect.dart';

class IngredientSelectScreen extends StatefulWidget {
  final Order order;
  final Difficulty difficulty;

  const IngredientSelectScreen({
    super.key,
    required this.order,
    required this.difficulty,
  });

  @override
  State<IngredientSelectScreen> createState() => _IngredientSelectScreenState();
}

class _IngredientSelectScreenState extends State<IngredientSelectScreen> {
  final Map<String, int> cart = {}; // ingredientId -> qty

  void add(String id) => setState(() => cart[id] = (cart[id] ?? 0) + 1);

  void remove(String id) => setState(() {
    final v = (cart[id] ?? 0) - 1;
    if (v <= 0) {
      cart.remove(id);
    } else {
      cart[id] = v;
    }
  });

  @override
  Widget build(BuildContext context) {
    final cartItems = cart.entries.map((e) => ingredientById(e.key)).toList();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            // iPad Gen10 portrait ~ 820, landscape ~ 1180
            final bool isTablet = w >= 740;

            // ✅ ห้าม scale ลง (คนแก่) -> scale มีแต่ 1.0..1.25
            final double scale = isTablet ? (w / 1024).clamp(1.05, 1.25) : 1.0;

            // ✅ Sidebar กว้างขึ้นบน Tablet (ให้เต็มจอ + อ่านง่าย)
            final double leftW = isTablet
                ? (w * 0.30).clamp(320.0, 420.0)
                : 260.0;

            final double rightW = w - leftW;

            // ✅ กำหนด "ขนาดช่องขั้นต่ำ" (ไม่ให้ของเล็ก)
            final double minTile = isTablet ? 220.0 : 180.0;

            // ✅ คำนวณจำนวนคอลัมน์ให้เต็มพื้นที่ โดยยังคง tile ใหญ่
            int cross = (rightW / minTile).floor();
            cross = cross.clamp(3, 5);

            // spacing (ไม่ลด)
            final double gap = isTablet ? 22.0 : 18.0;

            // ✅ ขยายขนาดของในตะกร้า/ปุ่มบน iPad (ไม่ย่อ)
            final double iconSize = isTablet ? 64 : 56;
            final double cartText = isTablet ? 18 : 16;
            final double headerText = isTablet ? 40 : 34;
            final double cookBtnH = isTablet ? 70 : 52;

            return Row(
              children: [
                // LEFT: Cart panel
                Container(
                  width: leftW,
                  color: const Color(0xFF9ED0FF),
                  padding: EdgeInsets.all(16 * scale),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE89B2C),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            AppText.get('cart'),
                            style: TextStyle(
                              fontSize: headerText,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      Expanded(
                        child: ListView.separated(
                          itemCount: cartItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final ing = cartItems[i];
                            final qty = cart[ing.id] ?? 0;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    ing.asset,
                                    width: iconSize,
                                    height: iconSize,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.image_not_supported,
                                      size: iconSize * 0.75,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "${AppText.name(ing.name)} x$qty",
                                      style: TextStyle(
                                        fontSize: cartText,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => remove(ing.id),
                                    child: Container(
                                      width: isTablet ? 48 : 38,
                                      height: isTablet ? 48 : 38,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFE45C5C),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "-",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isTablet ? 30 : 26,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 10),

                      ElevatedButton(
                        onPressed: () {
                          SoundFx.play(
                            SoundFx.gumgum,
                            volume: SoundFx.gumgumVolume,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResultScreen(
                                order: widget.order,
                                cart: Map<String, int>.from(cart),
                                difficulty: widget.difficulty,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, cookBtnH),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: TextStyle(
                            fontSize: isTablet ? 24 : 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: Text(AppText.get('cook')),
                      ),
                    ],
                  ),
                ),

                // RIGHT: Grid items
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          "assets/bg/supermarketbg.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                      // overlay ให้การ์ดเด่นขึ้น (ปรับ opacity ได้)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),

                      // Grid
                      Padding(
                        padding: EdgeInsets.all(gap),
                        child: GridView.builder(
                          itemCount: ingredients.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cross,
                            mainAxisSpacing: gap,
                            crossAxisSpacing: gap,
                            // ✅ ทำให้ช่องใหญ่ขึ้น (ไม่เตี้ย) สำหรับคนแก่กดง่าย
                            childAspectRatio: isTablet ? 1.05 : 1.0,
                          ),
                          itemBuilder: (context, i) {
                            final ing = ingredients[i];
                            return _IngredientCard(
                              asset: ing.asset,
                              onAdd: () => add(ing.id),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ✅ ต้องอยู่ "นอก" class State (top-level) เท่านั้น
class _IngredientCard extends StatelessWidget {
  final String asset;
  final VoidCallback onAdd;

  const _IngredientCard({required this.asset, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.orange, width: 6),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
          ),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7CB342),
              ),
              child: const Center(
                child: Text(
                  "+",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
