enum MindTalkMode {
  fixedOnly,   // ใช้ rule อย่างเดียว
  aiOnly,      // ใช้ AI อย่างเดียว
  auto,        // Fixed ก่อน ถ้าไม่เข้า → AI
}

extension MindTalkModeX on MindTalkMode {
  String get labelTH {
    switch (this) {
      case MindTalkMode.fixedOnly:
        return "Fixed";
      case MindTalkMode.aiOnly:
        return "AI";
      case MindTalkMode.auto:
        return "Auto";
    }
  }
}
