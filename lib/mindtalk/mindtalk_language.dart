enum SpeechLang { th, en, zh }

class LangConfig {
  const LangConfig({
    required this.label,
    required this.sttLocale,
    required this.ttsLocale,
    required this.flag,
    required this.promptName,
    required this.speechRate,
  });

  final String label;
  final String sttLocale;
  final String ttsLocale;
  final String flag;
  final String promptName;
  final double speechRate;
}

const Map<SpeechLang, LangConfig> kLangs = {
  SpeechLang.th: LangConfig(
    label: 'ไทย',
    sttLocale: 'th_TH',
    ttsLocale: 'th-TH',
    flag: '🇹🇭',
    promptName: 'Thai',
    speechRate: 0.46,
  ),
  SpeechLang.en: LangConfig(
    label: 'EN',
    sttLocale: 'en_US',
    ttsLocale: 'en-US',
    flag: '🇬🇧',
    promptName: 'English',
    speechRate: 0.48,
  ),
  SpeechLang.zh: LangConfig(
    label: '中文',
    sttLocale: 'zh_CN',
    ttsLocale: 'zh-CN',
    flag: '🇨🇳',
    promptName: 'Simplified Chinese',
    speechRate: 0.44,
  ),
};

String mindTalkGreeting(SpeechLang lang) => switch (lang) {
  SpeechLang.th => 'สวัสดีค่ะ วันนี้เป็นอย่างไรบ้างคะ',
  SpeechLang.en => 'Hello! How are you feeling today?',
  SpeechLang.zh => '你好！你今天感觉怎么样？',
};

String mindTalkFallback(SpeechLang lang) => switch (lang) {
  SpeechLang.th => 'ขอโทษนะคะ ตอนนี้เหมียวยังตอบไม่ได้ ลองพูดอีกครั้งได้ไหมคะ',
  SpeechLang.en => "Sorry, I couldn't answer that. Could you try again?",
  SpeechLang.zh => '对不起，我现在无法回答。你可以再说一次吗？',
};
