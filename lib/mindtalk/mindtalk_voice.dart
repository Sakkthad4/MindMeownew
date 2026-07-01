import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

// แชร์ enum/config จาก mindtalk_page.dart
// (ถ้าอยากให้สะอาดกว่า แนะนำย้าย SpeechLang/kLangs ไปไฟล์กลาง เช่น mindtalk_lang.dart)
import 'mindtalk_page.dart' show SpeechLang, LangConfig, kLangs;

class MindTalkVoiceController extends ChangeNotifier {
  // ---------------- Engines ----------------
  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  // ---------------- State ----------------
  bool _initialized = false;
  bool _isListening = false;
  String _partial = "";
  SpeechLang _lang = SpeechLang.th;

  // ---------------- Getters ----------------
  bool get isListening => _isListening;
  String get partial => _partial;
  SpeechLang get lang => _lang;
  LangConfig get langConfig => kLangs[_lang]!;
  bool get isReady => _initialized;

  // =============================================================
  // INIT
  // =============================================================
  Future<void> init() async {
    if (_initialized) return;

    _initialized = await _stt.initialize(
      onStatus: (s) {
        if (s == 'notListening' && _isListening) {
          _isListening = false;
          notifyListeners();
        }
      },
      onError: (_) {
        _isListening = false;
        _partial = "";
        notifyListeners();
      },
    );

    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.1);

    notifyListeners();
  }

  // =============================================================
  // LANGUAGE
  // =============================================================
  Future<void> setLang(SpeechLang newLang) async {
    if (_lang == newLang) return;
    if (_isListening) {
      await _stt.stop();
      _isListening = false;
      _partial = "";
    }
    _lang = newLang;
    notifyListeners();
  }

  // =============================================================
  // LISTENING
  // =============================================================
  Future<void> startListening() async {
    if (!_initialized) await init();
    if (!_initialized) return;
    if (_isListening) return;

    _partial = "";
    _isListening = true;
    notifyListeners();

    await _stt.listen(
      localeId: kLangs[_lang]!.sttLocale,
      onResult: (r) {
        _partial = r.recognizedWords;
        notifyListeners();
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  Future<String> stopListeningAndGetText() async {
    if (!_isListening) return _partial.trim();

    await _stt.stop();
    _isListening = false;

    final result = _partial.trim();
    notifyListeners();
    return result;
  }

  /// toggle ใช้แทน start+stop ในปุ่มเดียว
  /// คืนค่า text ถ้าหยุดฟังแล้วได้ข้อความ, คืน null ถ้าเพิ่งเริ่มฟัง
  Future<String?> toggle() async {
    if (_isListening) {
      return await stopListeningAndGetText();
    } else {
      await startListening();
      return null;
    }
  }

  // =============================================================
  // TTS
  // =============================================================
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _tts.setLanguage(kLangs[_lang]!.ttsLocale);
    } catch (e) {
      debugPrint('TTS setLanguage failed: $e');
    }
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  // =============================================================
  // CLEANUP
  // =============================================================
  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    super.dispose();
  }
}
