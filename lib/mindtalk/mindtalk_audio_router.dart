class MindTalkAudioRouteResult {
  const MindTalkAudioRouteResult({required this.replyText});
  final String replyText;
}

class _MindTalkRule {
  const _MindTalkRule({required this.keywords, required this.replyText});
  final List<String> keywords;
  final String replyText;
}

class MindTalkAudioRouter {
  static const _rules = <_MindTalkRule>[
    _MindTalkRule(
      keywords: ['สวัสดี', 'หวัดดี'],
      replyText: 'สวัสดีค่ะ วันนี้เป็นอย่างไรบ้างคะ',
    ),
    _MindTalkRule(
      keywords: ['hello', 'hi', 'good morning', 'good afternoon'],
      replyText: 'Hello! How are you feeling today?',
    ),
    _MindTalkRule(keywords: ['你好', '早上好', '下午好'], replyText: '你好！你今天感觉怎么样？'),
    _MindTalkRule(
      keywords: ['คุณชื่ออะไร', 'ชื่ออะไร', 'เธอชื่อ'],
      replyText: 'เหมียวชื่อเหมียวค่ะ ยินดีที่ได้รู้จักนะคะ',
    ),
    _MindTalkRule(
      keywords: ["what's your name", 'what is your name', 'your name'],
      replyText: "I'm Meow. It's lovely to meet you.",
    ),
    _MindTalkRule(
      keywords: ['你叫什么名字', '你名字叫什么', '叫什么'],
      replyText: '我叫 Meow，很高兴认识你。',
    ),
    _MindTalkRule(
      keywords: ['ขอบคุณ', 'ขอบใจ'],
      replyText: 'ยินดีค่ะ เหมียวดีใจที่ได้ช่วยนะคะ',
    ),
    _MindTalkRule(
      keywords: ['thank you', 'thanks'],
      replyText: "You're welcome. I'm glad I could help.",
    ),
    _MindTalkRule(keywords: ['谢谢', '多谢'], replyText: '不客气，很高兴能帮到你。'),
  ];

  MindTalkAudioRouteResult? tryRoute(String userText) {
    final text = userText.trim().toLowerCase();
    if (text.isEmpty) return null;

    for (final rule in _rules) {
      if (rule.keywords.any(
        (keyword) => text.contains(keyword.toLowerCase()),
      )) {
        return MindTalkAudioRouteResult(replyText: rule.replyText);
      }
    }
    return null;
  }
}
