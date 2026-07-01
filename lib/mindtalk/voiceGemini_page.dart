import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceGeminiPage extends StatefulWidget {
  const VoiceGeminiPage({super.key});

  @override
  State<VoiceGeminiPage> createState() => _VoiceGeminiPageState();
}

class _VoiceGeminiPageState extends State<VoiceGeminiPage> {
  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _busy = false;

  String _heardText = '';
  String _aiText = '';

  // 🔑 ใส่ API Key ของคุณ (แนะนำให้ใช้ key ใหม่)
  final String geminiApiKey = 'AIzaSyBfypAHz9lv62YWO__HM85Rb3JMCLoUn3g';

  @override
  void initState() {
    super.initState();
    _setupSamanthaVoice();
  }

  // 🎧 ตั้งค่าเสียง Samantha (Enhanced)
  Future<void> _setupSamanthaVoice() async {
    await _tts.setVolume(1.0);

    // ล็อกเสียงผู้หญิงเพราะธรรมชาติ
    await _tts.setVoice({"name": "Joelle (Enhanced)", "locale": "en-US"});

    // จูนให้นุ่ม ฟังสบาย
    await _tts.setSpeechRate(0.51);
    await _tts.setPitch(1.22);
  }

  Future<void> _speak(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;

    await _tts.stop();
    await _tts.speak(t);
  }

  Future<void> _startListening() async {
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

    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("STT initialize failed")));
      return;
    }

    setState(() {
      _isListening = true;
      _heardText = '';
    });

    await _stt.listen(
      onResult: (res) {
        if (!mounted) return;
        setState(() {
          _heardText = res.recognizedWords;
        });
      },
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  Future<void> _stopListeningAndAsk() async {
    setState(() => _isListening = false);
    await _stt.stop();

    final userText = _heardText.trim();
    if (userText.isEmpty) return;

    await _askGemini(userText);
  }

  Future<void> _askGemini(String userText) async {
    setState(() => _busy = true);

    try {
      final reply = await _callGemini(
        "You are a helpful assistant.\n"
        "Answer clearly and accurately.\n"
        "Use a calm, friendly tone.\n"
        //"English only.\n"
        "Keep it concise (2–6 sentences).\n\n"
        "User: $userText",
      );

      if (!mounted) return;
      setState(() => _aiText = reply);

      await _speak(reply);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gemini error: $e")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
      debugPrint("STATUS: ${resp.statusCode}");
      debugPrint("BODY: ${resp.body}");
      throw "HTTP ${resp.statusCode}";
    }

    final data = jsonDecode(resp.body);
    return data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"]
            ?.toString() ??
        "Sorry, I couldn't answer that.";
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _busy
        ? "Thinking..."
        : (_isListening ? "Listening..." : "Tap to speak");

    return Scaffold(
      appBar: AppBar(title: const Text("MindMeow (Samantha Enhanced)")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Card(
              title: "You said",
              text: _heardText.isEmpty ? "-" : _heardText,
            ),
            const SizedBox(height: 12),
            _Card(title: "AI reply", text: _aiText.isEmpty ? "-" : _aiText),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: Icon(_isListening ? Icons.stop : Icons.mic),
                label: Text(statusText),
                onPressed: _busy
                    ? null
                    : () async {
                        if (_isListening) {
                          await _stopListeningAndAsk();
                        } else {
                          await _startListening();
                        }
                      },
              ),
            ),

            const SizedBox(height: 10),

            if (_aiText.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.volume_up),
                  label: const Text("Speak again"),
                  onPressed: () => _speak(_aiText),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String text;
  const _Card({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }
}
