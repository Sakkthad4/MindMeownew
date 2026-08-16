import '../healthcare/models/mindtalk_emotion_event.dart';

class ConversationEmotionResult {
  const ConversationEmotionResult(this.emotion, this.confidence);

  final MindTalkEmotion emotion;
  final double confidence;
}

class MindTalkEmotionAnalyzer {
  const MindTalkEmotionAnalyzer();

  static const _keywords = <MindTalkEmotion, List<String>>{
    MindTalkEmotion.happy: [
      'ดีใจ',
      'มีความสุข',
      'สนุก',
      'สบายใจ',
      'ขอบคุณ',
      'happy',
      'great',
      'good',
      'excited',
      'glad',
      '开心',
      '高兴',
      '快乐',
      '谢谢',
    ],
    MindTalkEmotion.sad: [
      'เศร้า',
      'เสียใจ',
      'ร้องไห้',
      'เหงา',
      'หมดหวัง',
      'sad',
      'upset',
      'lonely',
      'cry',
      'hopeless',
      '难过',
      '伤心',
      '孤独',
      '哭',
    ],
    MindTalkEmotion.angry: [
      'โกรธ',
      'โมโห',
      'หงุดหงิด',
      'รำคาญ',
      'เกลียด',
      'angry',
      'mad',
      'annoyed',
      'furious',
      'hate',
      '生气',
      '愤怒',
      '讨厌',
      '烦',
    ],
    MindTalkEmotion.anxious: [
      'กังวล',
      'เครียด',
      'กลัว',
      'ไม่สบายใจ',
      'นอนไม่หลับ',
      'anxious',
      'worried',
      'stress',
      'afraid',
      'nervous',
      '焦虑',
      '担心',
      '压力',
      '害怕',
      '紧张',
    ],
  };

  ConversationEmotionResult analyze(List<String> recentUserMessages) {
    final messages = recentUserMessages
        .where((message) => message.trim().isNotEmpty)
        .toList();
    if (messages.isEmpty) {
      return const ConversationEmotionResult(MindTalkEmotion.neutral, 0.5);
    }

    final scores = <MindTalkEmotion, double>{
      for (final emotion in _keywords.keys) emotion: 0,
    };
    final window = messages.length > 6
        ? messages.sublist(messages.length - 6)
        : messages;

    for (var index = 0; index < window.length; index++) {
      final text = window[index].toLowerCase();
      final recencyWeight = 0.45 + (0.55 * (index + 1) / window.length);
      for (final entry in _keywords.entries) {
        for (final keyword in entry.value) {
          if (text.contains(keyword)) {
            scores[entry.key] = scores[entry.key]! + recencyWeight;
          }
        }
      }
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = ranked.first;
    if (best.value == 0) {
      return const ConversationEmotionResult(MindTalkEmotion.neutral, 0.55);
    }
    final confidence = (0.58 + best.value * 0.10).clamp(0.58, 0.92);
    return ConversationEmotionResult(best.key, confidence);
  }
}
