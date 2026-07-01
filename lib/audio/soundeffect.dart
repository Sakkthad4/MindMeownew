import 'package:audioplayers/audioplayers.dart';

class SoundFx {
  // ====== asset paths ======
  static const String correct = "assets/effects/correct.mp3";
  static const String incorrect = "assets/effects/incorrect.mp3";
  static const String hello = "assets/effects/Hello.MP3";
  static const String hungry = "assets/effects/hungry.MP3";
  static const String gumgum = "assets/effects/gumgum.MP3";
  static const String tap = "assets/effects/tap.mp3";

  // ====== volume presets ======
  static double masterVolume = 0.6;
  static const double correctVolume = 0.6;
  static const double helloVolume = 0.8;
  static const double hungryVolume = 0.8;
  static const double gumgumVolume = 0.8;
  static const double incorrectVolume = 0.6;
  static const double tapVolume = 0.3;

  static final AudioPlayer _player = AudioPlayer();

  /// เล่นเสียง effect
  static Future<void> play(String assetPath, {double? volume}) async {
    final v = (volume ?? masterVolume).clamp(0.0, 1.0);

    await _player.setVolume(v);
    await _player.stop(); // กันเสียงซ้อน (เหมาะกับ SFX)
    await _player.play(AssetSource(assetPath.replaceFirst('assets/', '')));
  }

  // ====== helper methods ======
  static Future<void> winFx() => play(correct, volume: correctVolume);

  static Future<void> loseFx() => play(incorrect, volume: incorrectVolume);

  static Future<void> helloFx() => play(hello, volume: helloVolume);

  static Future<void> hungryFx() => play(hungry, volume: hungryVolume);

  static Future<void> gumgumFx() => play(gumgum, volume: gumgumVolume);

  static Future<void> tapFx() => play(tap, volume: tapVolume);
}
