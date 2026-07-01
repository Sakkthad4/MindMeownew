class MindTalkAudioRouteResult {
  final String replyText;
  final String? assetAudioPath; // null = ใช้ TTS

  const MindTalkAudioRouteResult({
    required this.replyText,
    this.assetAudioPath,
  });
}

class _MindTalkRule {
  final List<String> keywords;
  final MindTalkAudioRouteResult result;

  const _MindTalkRule({required this.keywords, required this.result});
}

class MindTalkAudioRouter {
  MindTalkAudioRouter();

  static const List<_MindTalkRule> _rules = [
    // ------------------ ทักทาย ไทย ------------------
    _MindTalkRule(
      keywords: ["สวัสดี", "หวัดดี"],
      result: MindTalkAudioRouteResult(
        replyText: "สวัสดีค่า วันนี้เป็นยังไงบ้างคะ 🐱",
        assetAudioPath: "assets/effect/Hello.MP3",
      ),
    ),

    // ------------------ ทักทาย EN ------------------
    _MindTalkRule(
      keywords: ["hello", "hi", "good morning", "good afternoon"],
      result: MindTalkAudioRouteResult(
        replyText: "Hello! How are you today? 🐱",
        assetAudioPath: "assets/effect/Hello.MP3",
      ),
    ),

    // ------------------ ทักทาย จีน ------------------
    _MindTalkRule(
      keywords: ["你好", "早上好", "下午好"],
      result: MindTalkAudioRouteResult(
        replyText: "你好呀!今天过得怎么样呀。🐱",
        assetAudioPath: "assets/effect/Hello.MP3",
      ),
    ),

    // ------------------ ถามชื่อ ไทย ------------------
    _MindTalkRule(
      keywords: ["คุณชื่ออะไร", "ชื่ออะไร", "เธอชื่อ"],
      result: MindTalkAudioRouteResult(
        replyText: "เหมียวชื่อเหมียวค่ะ 🐱",
        assetAudioPath: "assets/effect/Hello.MP3",
      ),
    ),

    // ------------------ ถามชื่อ EN ------------------
    _MindTalkRule(
      keywords: ["what's your name", "what is your name", "your name"],
      result: MindTalkAudioRouteResult(
        replyText: "My name is Meow.",
        assetAudioPath: "assets/effect/Hello.MP3",
      ),
    ),

    // ------------------ ถามชื่อ จีน ------------------
    _MindTalkRule(
      keywords: ["你叫什么名字", "你名字叫什么", "叫什么"],
      result: MindTalkAudioRouteResult(
        replyText: "我叫 Meow,请多关照。",
        assetAudioPath: "assets/effect/Hello.MP3",
      ),
    ),

    // ------------------ กินข้าว ------------------
    _MindTalkRule(
      keywords: ["กินข้าว", "ทานข้าว", "กินข้าวแล้ว"],
      result: MindTalkAudioRouteResult(
        replyText: "ว้าว ฟังดูน่าอร่อยจังเลยนะคะ 😺",
        assetAudioPath: "assets/effect/Hello.MP3",
      ),
    ),

    // ------------------ ขอบคุณ (ใช้ TTS) ------------------
    _MindTalkRule(
      keywords: ["ขอบคุณ", "ขอบใจ", "thank you", "thanks", "谢谢"],
      result: MindTalkAudioRouteResult(
        replyText: "ไม่เป็นไรเลยค่ะ เหมียวดีใจที่ช่วยได้นะคะ 🐾",
        assetAudioPath: null,
      ),
    ),

    // ------------------ เศร้า (ใช้ TTS) ------------------
    _MindTalkRule(
      keywords: ["เศร้า", "เสียใจ", "ร้องไห้", "sad", "crying", "难过"],
      result: MindTalkAudioRouteResult(
        replyText: "เหมียวขอกอดแน่น ๆ นะคะ 💛",
        assetAudioPath: null,
      ),
    ),

    _MindTalkRule(
      keywords: ["เครียดจัง", "งานเยอะมาก", "น้ำตา", "stressed", "exhausted"],
      result: MindTalkAudioRouteResult(
        replyText: "พักผ่อนบ้างนะ เหมียวเป็นกำลังใจให้",
        assetAudioPath: "assets/effect/sleep.MP3",
      ),
    ),
  ];

  MindTalkAudioRouteResult? tryRoute(String userText) {
    final text = userText.trim().toLowerCase();
    if (text.isEmpty) return null; // ⬅ กัน empty input

    for (final rule in _rules) {
      for (final keyword in rule.keywords) {
        // ⬅ ข้าม keyword ว่างเปล่า + lowercase keyword ด้วย
        if (keyword.isEmpty) continue;
        if (text.contains(keyword.toLowerCase())) {
          return rule.result;
        }
      }
    }
    return null;
  }
}
