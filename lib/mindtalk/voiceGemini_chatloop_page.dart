import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceGeminiChatLoopPage extends StatefulWidget {
  const VoiceGeminiChatLoopPage({super.key});

  @override
  State<VoiceGeminiChatLoopPage> createState() =>
      _VoiceGeminiChatLoopPageState();
}

enum ChatState { idle, listening, thinking, speaking }

class _VoiceGeminiChatLoopPageState extends State<VoiceGeminiChatLoopPage> {
  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  // 🔑 ใส่ API KEY ของคุณ
  final String geminiApiKey = 'AIzaSyBsQICFFZFBPeVE91nj9Ho2V7VIgDFuhOg';

  ChatState _state = ChatState.idle;
  bool _sessionOn = false;
  bool _processing = false;

  // STT
  String _liveSpeech = '';
  Timer? _silenceTimer;

  // Silence detection (ตามที่ขอ)
  final Duration silenceWindow = const Duration(seconds: 2);

  // Chat history (เหมือน LINE)
  final List<Map<String, String>> messages = [];

  @override
  void initState() {
    super.initState();
    _setupTts();
    _wireTtsCallbacks();
  }

  // 🎧 ตั้งค่าเสียง Samantha (Enhanced)
  Future<void> _setupTts() async {
    await _tts.setVolume(1.0);
    await _tts.setVoice({"name": "Samantha (Enhanced)", "locale": "en-US"});
    await _tts.setSpeechRate(0.50);
    await _tts.setPitch(1.12);
  }

  void _wireTtsCallbacks() {
    _tts.setCompletionHandler(() async {
      if (!_sessionOn) {
        setState(() => _state = ChatState.idle);
        return;
      }

      // หลัง AI พูดจบ → กลับไปฟัง
      await Future.delayed(const Duration(milliseconds: 650));
      _startListening();
    });
  }

  // ▶️ เริ่ม / ⏹️ หยุด session
  Future<void> _toggleSession() async {
    if (_sessionOn) {
      await _stopSession();
    } else {
      await _startSession();
    }
  }

  Future<void> _startSession() async {
    setState(() {
      _sessionOn = true;
      _state = ChatState.listening;
      _liveSpeech = '';
    });

    await _tts.stop();
    await _stt.stop();
    _startListening();
  }

  Future<void> _stopSession() async {
    _silenceTimer?.cancel();
    _silenceTimer = null;

    setState(() {
      _sessionOn = false;
      _state = ChatState.idle;
      _liveSpeech = '';
    });

    await _stt.stop();
    await _tts.stop();
    _processing = false;
  }

  // 🎤 ฟังเสียงต่อเนื่อง
  Future<void> _startListening() async {
    if (!_sessionOn || _processing) return;

    await _tts.stop();
    await _stt.stop();

    final ok = await _stt.initialize(
      onError: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("STT error: ${e.errorMsg}")));
      },
    );

    if (!ok) return;

    setState(() {
      _state = ChatState.listening;
      _liveSpeech = '';
    });

    await _stt.listen(
      partialResults: true,
      listenMode: stt.ListenMode.confirmation,
      onResult: (res) {
        if (!mounted) return;

        _liveSpeech = res.recognizedWords;
        setState(() {});

        // รีเซ็ต timer ทุกครั้งที่มีเสียง
        _silenceTimer?.cancel();
        _silenceTimer = Timer(silenceWindow, _sendIfSilent);
      },
    );
  }

  // 🤫 เงียบครบ 2 วิ → ส่งให้ AI
  Future<void> _sendIfSilent() async {
    if (_processing || !_sessionOn) return;

    final text = _liveSpeech.trim();
    if (text.isEmpty) return;

    _processing = true;

    await _stt.stop();
    _silenceTimer?.cancel();

    // เพิ่มข้อความผู้ใช้
    messages.add({"role": "user", "text": text});
    setState(() {
      _state = ChatState.thinking;
      _liveSpeech = '';
    });

    try {
      final reply = await _callGeminiWithHistory(text);

      messages.add({"role": "ai", "text": reply});
      setState(() => _state = ChatState.speaking);

      await _tts.speak(reply);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gemini error: $e")));
      _processing = false;
      _startListening();
    }
  }

  // 🧠 Gemini พร้อม context แชต
  Future<String> _callGeminiWithHistory(String userText) async {
    final tail = messages.length > 8
        ? messages.sublist(messages.length - 8)
        : messages;

    final historyText = tail
        .map(
          (m) => "${m["role"] == "user" ? "User" : "Assistant"}: ${m["text"]}",
        )
        .join("\n");

    final prompt =
        """
You are a friendly assistant.
English only.
Answer accurately and naturally.
Keep replies concise (2–4 sentences).

Conversation so far:
$historyText

User: $userText
""";

    return _callGemini(prompt);
  }

  Future<String> _callGemini(String prompt) async {
    final uri = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$geminiApiKey",
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
      "generationConfig": {"temperature": 0.35, "maxOutputTokens": 220},
    };

    final resp = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      throw "HTTP ${resp.statusCode}";
    }

    final data = jsonDecode(resp.body);
    return data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"]
            ?.toString() ??
        "Sorry, I couldn't answer.";
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  String _stateLabel() {
    switch (_state) {
      case ChatState.listening:
        return "Listening… (auto-send after silence)";
      case ChatState.thinking:
        return "Thinking…";
      case ChatState.speaking:
        return "Speaking…";
      case ChatState.idle:
      default:
        return "Idle";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MindMeow – Hands-Free Talk")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_stateLabel()),
          ),

          // 💬 Chat list (เหมือน LINE)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final m = messages[i];
                final isUser = m["role"] == "user";

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blueAccent.withOpacity(0.2)
                          : Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(m["text"] ?? ""),
                  ),
                );
              },
            ),
          ),

          // ▶️ / ⏹️
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: Icon(_sessionOn ? Icons.stop_circle : Icons.play_circle),
                label: Text(
                  _sessionOn
                      ? "Stop conversation"
                      : "Start hands-free conversation",
                ),
                onPressed: _toggleSession,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
