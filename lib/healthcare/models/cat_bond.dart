import 'package:hive/hive.dart';

part 'cat_bond.g.dart';

@HiveType(typeId: 2) // อย่าให้ชนกับ GameResult(typeId:1)
class CatBond extends HiveObject {
  @HiveField(0)
  final int totalXp;

  @HiveField(1)
  final DateTime updatedAt;

  CatBond({required this.totalXp, required this.updatedAt});

  CatBond copyWith({int? totalXp, DateTime? updatedAt}) {
    return CatBond(
      totalXp: totalXp ?? this.totalXp,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
