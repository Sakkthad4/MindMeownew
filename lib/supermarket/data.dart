import 'models.dart';

const ingredients = <Ingredient>[
  //protein
  Ingredient(id: 'chicken', name: 'Chicken', asset: 'assets/ing/chicken.png'),
  Ingredient(id: 'pork', name: 'Pork', asset: 'assets/ing/pork.png'),
  Ingredient(id: 'salmon', name: 'Salmon', asset: 'assets/ing/salmon.png'),

  //carb.
  Ingredient(
    id: 'spaghetti',
    name: 'Spaghetti',
    asset: 'assets/ing/spaghetti.png',
  ),
  Ingredient(id: 'rice', name: 'Rice', asset: 'assets/ing/rice.png'),
  Ingredient(id: 'bread', name: 'Bread', asset: 'assets/ing/bread.png'),

  //veg.
  Ingredient(id: 'carrot', name: 'Carrot', asset: 'assets/ing/carrot.png'),
  Ingredient(
    id: 'broccoli',
    name: 'Broccoli',
    asset: 'assets/ing/broccoli.png',
  ),
  Ingredient(id: 'tomato', name: 'Tomato', asset: 'assets/ing/tomato.png'),
  Ingredient(id: 'onion', name: 'Onion', asset: 'assets/ing/onion.png'),
  Ingredient(id: 'pepper', name: 'Pepper', asset: 'assets/ing/pepper.png'),
  Ingredient(id: 'potato', name: 'Potato', asset: 'assets/ing/potato.png'),
  Ingredient(id: 'lettuce', name: 'Lettuce', asset: 'assets/ing/lettuce.png'),
  Ingredient(
    id: 'mushroom',
    name: 'Mushroom',
    asset: 'assets/ing/mushroom.png',
  ),
];

const recipeTemplates = <RecipeTemplate>[
  // ---- เดิมของคุณ ----
  RecipeTemplate(
    id: 'chicken_bowl',
    name: 'Chicken Bowl',
    plateAsset: 'assets/plates/chicken_bowl.png',
    ingredientIds: ['chicken', 'rice', 'broccoli', 'carrot'],
  ),
  /*RecipeTemplate(
    id: 'veggie_salad',
    name: 'Veg Salad',
    plateAsset: 'assets/plates/chicken_bowl.png',
    ingredientIds: ['broccoli', 'carrot', 'tomato', 'onion'],
  ),
  RecipeTemplate(
    id: 'stir_fry',
    name: 'Stir Fry',
    plateAsset: 'assets/plates/chicken_bowl.png',
    ingredientIds: ['onion', 'pepper', 'potato', 'carrot'],
  ),*/

  // ---- ✅ เพิ่มเมนูใหม่ (ชื่ออังกฤษสั้น) ----

  // ข้าวผัด
  RecipeTemplate(
    id: 'fried_rice',
    name: 'Fried Rice',
    plateAsset: 'assets/plates/fried_rice.png',
    ingredientIds: ['rice', 'onion', 'tomato', 'mushroom'],
  ),

  // สเต็กแซลมอน + มะเขือเทศ + ผักกาด
  RecipeTemplate(
    id: 'salmon_steak',
    name: 'Salmon Steak',
    plateAsset: 'assets/plates/salmon_steak.png',
    ingredientIds: ['salmon', 'tomato', 'lettuce', 'onion'],
  ),

  // สตูเนื้อ
  RecipeTemplate(
    id: 'beef_stew',
    name: 'Beef Stew',
    plateAsset: 'assets/plates/beef_stew.png',
    ingredientIds: ['potato', 'onion', 'tomato', 'mushroom'],
  ),

  // สลัดผักรวม
  RecipeTemplate(
    id: 'mix_salad',
    name: 'Mix Salad',
    plateAsset: 'assets/plates/mix_salad.png',
    ingredientIds: ['lettuce', 'tomato', 'onion', 'carrot'],
  ),

  // สปาเก็ตตี้
  RecipeTemplate(
    id: 'spaghetti_plate',
    name: 'Spaghetti',
    plateAsset: 'assets/plates/spaghetti.png',
    ingredientIds: ['spaghetti', 'tomato', 'onion', 'mushroom'],
  ),

  // แซนวิช
  RecipeTemplate(
    id: 'sandwich',
    name: 'Sandwich',
    plateAsset: 'assets/plates/sandwich.png',
    ingredientIds: ['bread', 'lettuce', 'tomato', 'pork'],
  ),

  // สเต็กเนื้อกับผัก (ผมใช้ chicken/pork แทน beef เพราะของเดิมไม่มี “beef”)
  // ถ้าคุณมีเนื้อวัวจริง ๆ ก็เพิ่ม Ingredient(id:'beef',...) แล้วเปลี่ยนเป็น beef ได้
  RecipeTemplate(
    id: 'steak_veg',
    name: 'Steak',
    plateAsset: 'assets/plates/steak_veg.png',
    ingredientIds: ['pork', 'lettuce', 'tomato', 'mushroom'],
  ),
];

Ingredient ingredientById(String id) {
  return ingredients.firstWhere((x) => x.id == id);
}
