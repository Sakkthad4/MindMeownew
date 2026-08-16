import 'dart:async';
import 'package:flutter/material.dart';
import '../app_language.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import '../healthcare/data/mindtalk_emotion_store.dart';
import '../healthcare/models/mindtalk_emotion_event.dart';
import 'mindtalk_emotion_picker.dart';
import 'emotion_camera_page.dart';
import 'mindtalk_audio_router.dart';
import 'mindtalk_ai_service.dart';
import 'mindtalk_emotion_analyzer.dart';
import 'mindtalk_language.dart';

enum MindTalkMode {
  fixedOnly, // ใช้ rule อย่างเดียว
  aiOnly, // ใช้ AI อย่างเดียว
  auto, // FIX ก่อน → ไม่เข้าใช้ AI
}

// =============================================================
// MULTI-LANGUAGE SUPPORT
// =============================================================
class MindTalkPage extends StatefulWidget {
  const MindTalkPage({super.key});

  @override
  State<MindTalkPage> createState() => _MindTalkPageState();
}

class _MindTalkPageState extends State<MindTalkPage> {
  // ---------------- Colors ----------------
  static const orange = Color(0xFFFFA726);
  static const blueBorder = Color(0xFF6BB8FF);
  static const greenMood = Color(0xFF7ED957);

  // Use Gemini for the whole conversation so even greetings and short replies
  // can take the preceding context into account.
  final MindTalkMode _mode = MindTalkMode.aiOnly;

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
  final MindTalkAiService _ai = MindTalkAiService();
  final MindTalkEmotionStore _emotionStore = MindTalkEmotionStore();
  final MindTalkEmotionAnalyzer _emotionAnalyzer = MindTalkEmotionAnalyzer();
  final String _emotionSessionId = DateTime.now().microsecondsSinceEpoch
      .toString();
  bool _processing = false;

  // ---------------- ESP32 CAM ----------------
  bool useEsp32Cam = false;
  final espIpCtrl = TextEditingController(text: '192.168.43.123');

  // ---------------- Chat ----------------
  final List<_Msg> _msgs = [_Msg.bot(mindTalkGreeting(SpeechLang.th))];
  final _scrollCtrl = ScrollController();

  // ---------------- Emotion ----------------
  DetectedEmotion _userEmotion = DetectedEmotion.neutral;

  // =============================================================

  @override
  void initState() {
    super.initState();
    _currentLang = switch (AppLanguageController.current.value) {
      AppLanguage.thai => SpeechLang.th,
      AppLanguage.chinese => SpeechLang.zh,
      AppLanguage.english => SpeechLang.en,
    };
    _msgs
      ..clear()
      ..add(_Msg.bot(mindTalkGreeting(_currentLang)));
    _initStt();
    _setupTts();
  }

  Future<void> _setupTts() async {
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
    await _tts.setPitch(1.0);
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
    final config = kLangs[_currentLang]!;
    try {
      await _tts.stop();
      await _tts.setLanguage(config.ttsLocale);
      await _tts.setSpeechRate(config.speechRate);
    } catch (e) {
      debugPrint('TTS setLanguage failed: $e');
    }
    await _tts.speak(_speechFriendly(text));
  }

  String _speechFriendly(String text) => text
      .replaceAll(RegExp(r'[*_#`>]'), '')
      .replaceAll(RegExp(r'https?://\S+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // =============================================================
  // 🎤 MIC BUTTON
  // =============================================================
  Future<void> _toggleMic() async {
    if (_processing) return;
    if (!_sttReady) {
      await _initStt();
      if (!_sttReady) return;
    }

    if (!_listening) {
      await _tts.stop();
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
        _recordConversationEmotion();
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

  Future<String> _askGemini(String userText) async {
    try {
      final history = _msgs
          .take(_msgs.length - 1)
          .map((msg) => (isUser: !msg.isBot, text: msg.text))
          .toList();
      return await _ai.reply(
        userText: userText,
        language: _currentLang,
        history: history,
      );
    } catch (e) {
      debugPrint("GEMINI ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gemini: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return mindTalkFallback(_currentLang);
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

  void _recordConversationEmotion() {
    final recentUserMessages = _msgs
        .where((message) => !message.isBot)
        .map((message) => message.text)
        .toList();
    final result = _emotionAnalyzer.analyze(recentUserMessages);
    unawaited(
      _emotionStore.record(
        emotion: result.emotion,
        source: MindTalkEmotionSource.conversation,
        confidence: result.confidence,
        sessionId: _emotionSessionId,
      ),
    );
  }

  void _recordCameraEmotion(CameraEmotionObservation observation) {
    final emotion = switch (observation.emotion) {
      DetectedEmotion.happy => MindTalkEmotion.happy,
      DetectedEmotion.sad => MindTalkEmotion.sad,
      DetectedEmotion.neutral => MindTalkEmotion.neutral,
    };
    setState(() => _userEmotion = observation.emotion);
    unawaited(
      _emotionStore.record(
        emotion: emotion,
        source: MindTalkEmotionSource.camera,
        confidence: observation.confidence,
        sessionId: _emotionSessionId,
      ),
    );
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
        ..add(_Msg.bot(mindTalkGreeting(_currentLang)));
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
    _ai.dispose();
    espIpCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleFixedOnly(String userText) async {
    final fixed = _audioRouter.tryRoute(userText);

    if (fixed == null) {
      final msg = mindTalkFallback(_currentLang);
      _addBotMessage(msg);
      await _speak(msg);
      return;
    }

    _addBotMessage(fixed.replyText);
    await _speak(fixed.replyText);
  }

  Future<void> _handleAiOnly(String userText) async {
    await _replyWithAi(userText);
  }

  Future<void> _handleAuto(String userText) async {
    final fixed = _audioRouter.tryRoute(userText);

    if (fixed != null) {
      _addBotMessage(fixed.replyText);
      await _speak(fixed.replyText);
      return;
    }

    await _replyWithAi(userText);
  }

  Future<void> _replyWithAi(String userText) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final aiReply = await _askGemini(userText);
      if (!mounted) return;
      _addBotMessage(aiReply);
      await _speak(aiReply);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
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
                    Colors.white.withValues(alpha: 0.35),
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
                  AppText.get('conversation'),
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
                    await _tts.stop();
                    if (!mounted) return;
                    setState(() {
                      _currentLang = lang;
                      _listening = false;
                      _partial = "";
                      _msgs
                        ..clear()
                        ..add(_Msg.bot(mindTalkGreeting(lang)));
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
                              onEmotionDetected: _recordCameraEmotion,
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
                      _processing
                          ? Icons.hourglass_top
                          : _listening
                          ? Icons.stop
                          : Icons.mic,
                      size: w * 0.06,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              Positioned.fromRect(
                rect: actionsRect,
                child: _ActionPanelImages(w: w),
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
                    child: Text(AppText.get('reset')),
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
            color: Colors.black.withValues(alpha: 0.1),
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

  const _ActionPanelImages({required this.w});

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
      placeholder: Center(child: Text(AppText.get('connecting'))),
    );
  }
}
