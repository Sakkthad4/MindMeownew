class Ingredient {
  final String id;
  final String name;
  final String asset;
  const Ingredient({required this.id, required this.name, required this.asset});
}

/// Template ของเมนู (ยังไม่มีจำนวน)
class RecipeTemplate {
  final String id;
  final String name;
  final String plateAsset;
  final List<String> ingredientIds;
  const RecipeTemplate({
    required this.id,
    required this.name,
    required this.plateAsset,
    required this.ingredientIds,
  });
}

/// ออเดอร์ที่สุ่มแล้ว (มีจำนวน)
class Order {
  final String id;
  final String name;
  final String plateAsset;

  /// ingredientId -> required quantity
  final Map<String, int> requiredQty;

  const Order({
    required this.id,
    required this.name,
    required this.plateAsset,
    required this.requiredQty,
  });
}

/// ✅ เพิ่มถ้าไฟล์คุณยังไม่มี
enum Difficulty { easy, normal, hard }
