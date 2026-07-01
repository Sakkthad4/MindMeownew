enum CatEmotion {
  calm,
  happy,
  sad,
  angry,
}

/// Extension สำหรับ mapping emotion → eye mode (ESP ใช้)
extension CatEmotionX on CatEmotion {
  /// string ที่ส่งไป ESP32

  /// label ภาษาไทย (ใช้ใน UI)
  String get labelTH {
    switch (this) {
      case CatEmotion.calm:
        return "สงบ";
      case CatEmotion.happy:
        return "ดีใจ";
      case CatEmotion.sad:
        return "เศร้า";
      case CatEmotion.angry:
        return "โกรธ";
    }
  }
}
