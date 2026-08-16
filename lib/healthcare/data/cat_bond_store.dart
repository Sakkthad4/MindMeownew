import 'package:flutter/foundation.dart'; // ✅ ValueListenable
import 'package:hive_flutter/hive_flutter.dart'; // ✅ box.listenable()

import '../models/cat_bond.dart';

class CatBondProgress {
  final int level; // เริ่ม 1
  final int xpInLevel;
  final int needForLevel;
  final int totalXp;

  const CatBondProgress({
    required this.level,
    required this.xpInLevel,
    required this.needForLevel,
    required this.totalXp,
  });

  double get percent =>
      needForLevel == 0 ? 0.0 : (xpInLevel / needForLevel).clamp(0.0, 1.0);
}

class CatBondStore {
  static const String boxName = 'cat_bond';
  static const String keyMain = 'main';

  static Future<void> init() async {
    await Hive.openBox<CatBond>(boxName);
    final box = Hive.box<CatBond>(boxName);

    if (!box.containsKey(keyMain)) {
      await box.put(keyMain, CatBond(totalXp: 0, updatedAt: DateTime.now()));
    }
  }

  Box<CatBond> get _box => Hive.box<CatBond>(boxName);

  CatBond get _current =>
      _box.get(keyMain) ?? CatBond(totalXp: 0, updatedAt: DateTime.now());

  /// เพิ่ม XP
  Future<void> addXp({
    required int amount,
    required String source, // เผื่อคุณจะ log ทีหลัง
  }) async {
    final now = DateTime.now();
    final next = _current.copyWith(
      totalXp: (_current.totalXp + amount).clamp(0, 1 << 30),
      updatedAt: now,
    );
    await _box.put(keyMain, next);
  }

  /// คำนวณ progress ปัจจุบัน
  CatBondProgress getProgress() {
    return _calcProgress(_current.totalXp);
  }

  /// ให้ UI ฟังการเปลี่ยนแปลง (ใช้กับ ValueListenableBuilder)
  ValueListenable<Box<CatBond>> listenable() {
    return _box.listenable(keys: [keyMain]);
  }

  // ===== Level rules =====
  // Lv1 ใช้ 10, Lv2 ใช้ 20, Lv3 ใช้ 40, ... (คูณสองไปเรื่อยๆ)
  int _needForLevel(int level) {
    return 10 * (1 << (level - 1)); // 10 * 2^(level-1)
  }

  CatBondProgress _calcProgress(int totalXp) {
    int level = 1;
    int remaining = totalXp;

    while (true) {
      final need = _needForLevel(level);
      if (remaining < need) {
        return CatBondProgress(
          level: level,
          xpInLevel: remaining,
          needForLevel: need,
          totalXp: totalXp,
        );
      }
      remaining -= need;
      level++;
      if (level > 200) {
        return CatBondProgress(
          level: 200,
          xpInLevel: 0,
          needForLevel: _needForLevel(200),
          totalXp: totalXp,
        );
      }
    }
  }
}
