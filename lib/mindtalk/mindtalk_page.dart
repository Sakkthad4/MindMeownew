import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import 'mindtalk_emotion.dart';
import 'mindtalk_emotion_picker.dart';
import 'emotion_camera_page.dart';
import 'mindtalk_audio_router.dart';
import 'mindtalk_chat.dart';

enum MindTalkMode {
  fixedOnly, // ใช้ rule อย่างเดียว
  aiOnly, // ใช้ AI อย่างเดียว
  auto, // FIX ก่อน → ไม่เข้าใช้ AI
}

// =============================================================
// MULTI-LANGUAGE SUPPORT
// =============================================================
enum SpeechLang { th, en, zh }

class LangConfig {
  final String label; // ไทย, EN, 中文
  final String sttLocale; // th_TH, en_US, zh_CN
  final String ttsLocale; // th-TH, en-US, zh-CN
  final String flag;
  const LangConfig(this.label, this.sttLocale, this.ttsLocale, this.flag);
}

const Map<SpeechLang, LangConfig> kLangs = {
  SpeechLang.th: LangConfig('ไทย', 'th_TH', 'th-TH', '🇹🇭'),
  SpeechLang.en: LangConfig('EN', 'en_US', 'en-US', '🇬🇧'),
  SpeechLang.zh: LangConfig('中文', 'zh_CN', 'zh-CN', '🇨🇳'),
};

const String _systemPrompt = '''
คุณคือแมวน้อยแสนน่ารัก ชื่อ "เหมียว"
พูดจาอบอุ่น เป็นมิตร

⚡ สำคัญ: ตอบเป็น "ภาษาเดียวกับที่ผู้ใช้พูด" เสมอ
- ถ้าผู้ใช้พูดไทย → ตอบไทย
- ถ้าผู้ใช้พูดอังกฤษ → ตอบอังกฤษ
- ถ้าผู้ใช้พูดจีน (中文) → ตอบจีน

ตอบสั้น กระชับ ถ้าผู้ใช้เศร้าให้ปลอบ ถ้าดีใจให้ชื่นชม
ห้ามตอบเชิงเทคนิคจนเกินไป ถ้าเขาถามสาระต้องตอบให้ตรงประเด็น
ไม่ตอบอะไรที่อันตรายหรือสื่อถึงความอันตรายซึ่งนำไปถึงแก่ชีวิตและทรัพย์สิน
สร้างความสุขและกำลังใจ
''';

class MindTalkPage extends StatefulWidget {
  const MindTalkPage({super.key});

  @override
  State<MindTalkPage> createState() => _MindTalkPageState();
}

class _MindTalkPageState extends State<MindTalkPage> {
  // ---------------- Colors ----------------
  static const orange = Color(0xFFFFA726);
  static const blueBorder = Color(0xFF6BB8FF);
  static const textGray = Color(0xFF5F5F5F);
  static const greenMood = Color(0xFF7ED957);

  final MindTalkMode _mode = MindTalkMode.auto;

  // ---------------- LANGUAGE ----------------
  SpeechLang _currentLang = SpeechLang.th;

  // ---------------- STT ----------------
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttReady = false;
  bool _listening = false;
  String _partial = "";

  // ---------------- TTS + AI ----------------
  final FlutterTts _tts = FlutterTts();
  final MindTalkAudioRouter _audioRouter = MindTalkAudioRouter();
  final String geminiApiKey = 'AIzaSyBfypAHz9lv62YWO__HM85Rb3JMCLoUn3g';

  // ---------------- ESP32 CAM ----------------
  bool useEsp32Cam = true;
  final espIpCtrl = TextEditingController(text: '192.168.43.123');

  // ---------------- Chat ----------------
  final List<_Msg> _msgs = [_Msg.bot("Hello How are you today")];
  final List<_Msg> _initialMsgs = [_Msg.bot("Hello How are you today")];
  final _scrollCtrl = ScrollController();

  // ---------------- Emotion ----------------
  DetectedEmotion _userEmotion = DetectedEmotion.neutral;
  CatEmotion _catEmotion = CatEmotion.calm;

  // =============================================================

  @override
  void initState() {
    super.initState();
    _initStt();
    _setupTts();
  }

  Future<void> _setupTts() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.1);
  }

  Future<void> _initStt() async {
    final ok = await _stt.initialize(
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'notListening' && _listening) {
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _partial = "";
        });
      },
    );
    if (!mounted) return;
    setState(() => _sttReady = ok);
  }

  /// ตั้งภาษาให้ TTS ก่อนพูดทุกครั้ง
  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _tts.setLanguage(kLangs[_currentLang]!.ttsLocale);
    } catch (e) {
      debugPrint('TTS setLanguage failed: $e');
    }
    await _tts.speak(text);
  }

  /// ข้อความ fallback ตามภาษาปัจจุบัน
  String _fallbackError() {
    switch (_currentLang) {
      case SpeechLang.en:
        return "I'm a bit confused right now 🐱";
      case SpeechLang.zh:
        return "我现在有点糊涂了 🐱";
      case SpeechLang.th:
        return "เหมียวงงไปนิดนึงค่ะ 🐱";
    }
  }

  // =============================================================
  // 🎤 MIC BUTTON
  // =============================================================
  Future<void> _toggleMic() async {
    if (!_sttReady) {
      await _initStt();
      if (!_sttReady) return;
    }

    if (!_listening) {
      setState(() {
        _partial = "";
        _listening = true;
      });

      await _stt.listen(
        localeId: kLangs[_currentLang]!.sttLocale,
        onResult: (r) {
          if (!mounted) return;
          setState(() => _partial = r.recognizedWords);
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } else {
      await _stt.stop();
      final said = _partial.trim();
      setState(() => _listening = false);

      if (said.isNotEmpty) {
        _addUserMessage(said);
        await _handleUserText(said);
      }
    }
  }

  // =============================================================
  // 🧠 FIXED → AI → TTS
  // =============================================================
  Future<void> _handleUserText(String userText) async {
    switch (_mode) {
      case MindTalkMode.fixedOnly:
        await _handleFixedOnly(userText);
        break;
      case MindTalkMode.aiOnly:
        await _handleAiOnly(userText);
        break;
      case MindTalkMode.auto:
        await _handleAuto(userText);
        break;
    }
  }

  Future<String> _askGemini(String prompt) async {
    try {
      final uri = Uri.parse(
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent"
        "?key=$geminiApiKey",
      );

      final body = {
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": prompt},
            ],
          },
        ],
        "generationConfig": {
          "temperature": 0.5,
          "topP": 0.95,
          "topK": 64,
          "maxOutputTokens": 500,
        },
      };

      final resp = await http.post(
        uri,
        headers: const {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      debugPrint("GEMINI STATUS: ${resp.statusCode}");

      if (resp.statusCode != 200) {
        debugPrint("GEMINI BODY: ${resp.body}");
        return _fallbackError();
      }

      final data = jsonDecode(resp.body);
      final candidates = data["candidates"];
      if (candidates == null || candidates.isEmpty) {
        return _fallbackError();
      }

      final parts = candidates[0]["content"]?["parts"];
      if (parts == null || parts.isEmpty) {
        return _fallbackError();
      }

      return parts[0]["text"]?.toString().trim() ?? _fallbackError();
    } catch (e) {
      debugPrint("GEMINI ERROR: $e");
      return _fallbackError();
    }
  }

  // =============================================================
  // 💬 CHAT HELPERS
  // =============================================================
  void _addUserMessage(String text) {
    setState(() {
      _msgs.add(_Msg.user(text));
      _partial = "";
    });
    _scrollToBottom();
  }

  void _addBotMessage(String text) {
    setState(() => _msgs.add(_Msg.bot(text)));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _resetChat() {
    setState(() {
      _msgs
        ..clear()
        ..addAll(_initialMsgs);
      _partial = "";
      _listening = false;
    });
    _stt.stop();
    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleFixedOnly(String userText) async {
    final fixed = _audioRouter.tryRoute(userText);

    if (fixed == null) {
      final msg = _fallbackError();
      _addBotMessage(msg);
      await _speak(msg);
      return;
    }

    _addBotMessage(fixed.replyText);
    await _speak(fixed.replyText);
  }

  Future<void> _handleAiOnly(String userText) async {
    final langName = kLangs[_currentLang]!.label;
    final prompt =
        '''
$_systemPrompt

ผู้ใช้กำลังพูดภาษา: $langName
ผู้ใช้พูดว่า:
$userText
''';

    final aiReply = await _askGemini(prompt);
    _addBotMessage(aiReply);
    await _speak(aiReply);
  }

  Future<void> _handleAuto(String userText) async {
    final fixed = _audioRouter.tryRoute(userText);

    if (fixed != null) {
      _addBotMessage(fixed.replyText);
      await _speak(fixed.replyText);
      return;
    }

    final langName = kLangs[_currentLang]!.label;
    final prompt =
        '''
$_systemPrompt

ผู้ใช้กำลังพูดภาษา: $langName
ผู้ใช้พูดว่า:
$userText
''';

    final aiReply = await _askGemini(prompt);
    _addBotMessage(aiReply);
    await _speak(aiReply);
  }

  // =============================================================
  // 🎨 UI
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;

          Rect r(double l, double t, double rw, double rh) =>
              Rect.fromLTWH(w * l, h * t, w * rw, h * rh);

          final titleRect = r(0.03, 0.06, 0.60, 0.12);
          final chatRect = r(0.02, 0.18, 0.64, 0.48);
          final camRect = r(0.72, 0.08, 0.26, 0.40);
          final moodRect = r(0.76, 0.50, 0.20, 0.08);
          final actionsRect = r(0.60, 0.70, 0.38, 0.23);

          return Stack(
            children: [
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.35),
                    BlendMode.darken,
                  ),
                  child: Image.asset(
                    "assets/bg/mindtalkbg.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              Positioned.fromRect(
                rect: titleRect,
                child: Text(
                  "Conversation",
                  style: TextStyle(
                    fontSize: w * 0.055,
                    fontWeight: FontWeight.w900,
                    color: orange,
                  ),
                ),
              ),

              // 🌐 Language switcher
              Positioned(
                top: h * 0.07,
                right: w * 0.30,
                child: _LangSwitcher(
                  current: _currentLang,
                  onChanged: (lang) async {
                    if (_listening) await _stt.stop();
                    if (!mounted) return;
                    setState(() {
                      _currentLang = lang;
                      _listening = false;
                      _partial = "";
                    });
                  },
                ),
              ),

              Positioned.fromRect(
                rect: chatRect,
                child: _ChatScrollArea(
                  messages: _msgs,
                  tempUserText: (_listening && _partial.isNotEmpty)
                      ? _partial
                      : null,
                  controller: _scrollCtrl,
                ),
              ),

              Positioned.fromRect(
                rect: camRect,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("ESP32-CAM"),
                      value: useEsp32Cam,
                      onChanged: (v) => setState(() => useEsp32Cam = v),
                    ),
                    TextField(
                      controller: espIpCtrl,
                      decoration: const InputDecoration(labelText: "ESP32 IP"),
                    ),
                    Expanded(
                      child: useEsp32Cam
                          ? Esp32CamStreamView(ip: espIpCtrl.text.trim())
                          : EmotionCameraPage(
                              onEmotionDetected: (e) =>
                                  setState(() => _userEmotion = e),
                            ),
                    ),
                  ],
                ),
              ),

              Positioned.fromRect(
                rect: moodRect,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: greenMood,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _userEmotion.name,
                    style: TextStyle(
                      fontSize: w * 0.03,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: (w / 2) - (w * 0.13 / 2),
                top: h * 0.72,
                child: GestureDetector(
                  onTap: _toggleMic,
                  child: Container(
                    width: w * 0.13,
                    height: w * 0.13,
                    decoration: const BoxDecoration(
                      color: orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _listening ? Icons.stop : Icons.mic,
                      size: w * 0.06,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              Positioned.fromRect(
                rect: actionsRect,
                child: _ActionPanelImages(
                  w: w,
                  onEmotionSelected: (emo) {
                    setState(() => _catEmotion = emo);
                  },
                ),
              ),

              Positioned(
                left: 18,
                bottom: 18,
                child: GestureDetector(
                  onTap: _resetChat,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: orange, width: 4),
                    ),
                    child: const Text("Reset"),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================
// LANGUAGE SWITCHER
// =============================================================
class _LangSwitcher extends StatelessWidget {
  final SpeechLang current;
  final ValueChanged<SpeechLang> onChanged;

  const _LangSwitcher({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _MindTalkPageState.orange, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: SpeechLang.values.map((lang) {
          final cfg = kLangs[lang]!;
          final selected = lang == current;
          return GestureDetector(
            onTap: () => onChanged(lang),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? _MindTalkPageState.orange
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(cfg.flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    cfg.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================
// UI helper widgets (เดิม)
// =============================================================
class _ChatScrollArea extends StatelessWidget {
  final List<_Msg> messages;
  final String? tempUserText;
  final ScrollController controller;

  const _ChatScrollArea({
    required this.messages,
    required this.tempUserText,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: messages.length + (tempUserText != null ? 1 : 0),
      itemBuilder: (_, i) {
        final isTemp = tempUserText != null && i == messages.length;
        final msg = isTemp ? _Msg.user(tempUserText!) : messages[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: _BubbleRow(msg: msg),
        );
      },
    );
  }
}

class _BubbleRow extends StatelessWidget {
  final _Msg msg;
  const _BubbleRow({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isBot = msg.isBot;
    final color = isBot
        ? _MindTalkPageState.orange
        : _MindTalkPageState.blueBorder;

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color, width: 4),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _ActionPanelImages extends StatelessWidget {
  final double w;
  final ValueChanged<CatEmotion> onEmotionSelected;

  const _ActionPanelImages({required this.w, required this.onEmotionSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(w * 0.010),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(w * 0.030),
        border: Border.all(color: _MindTalkPageState.orange, width: w * 0.006),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ImgSquare(
            bg: const Color(0xFFEAF7FF),
            border: const Color(0xFF66B5FF),
            assetPath: "assets/icons/fish.png",
            onTap: () {},
          ),
          _ImgSquare(
            bg: const Color(0xFFEFE9FF),
            border: const Color(0xFF8E7CFF),
            assetPath: "assets/icons/music.png",
            onTap: () {},
          ),
          _ImgSquare(
            bg: const Color(0xFFFFF0B8),
            border: const Color(0xFFFFD34D),
            assetPath: "assets/icons/smile.png",
            onTap: () async {
              final emotion = await showCatEmotionPicker(context);
              if (emotion == null) return;
            },
          ),
        ],
      ),
    );
  }
}

class _ImgSquare extends StatelessWidget {
  final Color bg;
  final Color border;
  final String assetPath;
  final VoidCallback? onTap;

  const _ImgSquare({
    required this.bg,
    required this.border,
    required this.assetPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: border, width: 9),
        ),
        padding: const EdgeInsets.all(16),
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }
}

class _Msg {
  final bool isBot;
  final String text;
  _Msg(this.isBot, this.text);

  factory _Msg.bot(String t) => _Msg(true, t);
  factory _Msg.user(String t) => _Msg(false, t);
}

class Esp32CamStreamView extends StatefulWidget {
  final String ip;
  const Esp32CamStreamView({super.key, required this.ip});

  @override
  State<Esp32CamStreamView> createState() => _Esp32CamStreamViewState();
}

class _Esp32CamStreamViewState extends State<Esp32CamStreamView> {
  late VlcPlayerController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = VlcPlayerController.network(
      'http://${widget.ip}:81/stream',
      autoPlay: true,
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VlcPlayer(
      controller: _ctl,
      aspectRatio: 1,
      placeholder: const Center(child: Text('Connecting...')),
    );
  }
}
