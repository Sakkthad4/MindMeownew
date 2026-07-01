import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class Bgm {
  Bgm._();
  static final Bgm instance = Bgm._();

  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;

  final ValueNotifier<bool> muted = ValueNotifier(false);

  Future<void> _prepare() async {
    if (_ready) return;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.25);
    _ready = true;
  }

  Future<void> play(String asset) async {
    await _prepare();
    await _player.stop();
    await _player.play(AssetSource(asset));
    if (muted.value) {
      await _player.pause();
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> toggleMute() async {
    muted.value = !muted.value;
    if (muted.value) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }
}
