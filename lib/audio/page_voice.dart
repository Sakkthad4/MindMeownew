import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

class VoiceAssets {
  const VoiceAssets._();

  static const randomMenu = 'assets/voice/randommenu.mp3';
  static const remember = 'assets/voice/remember.mp3';
  static const hungry = 'assets/voice/hungry.mp3';
  static const delicious = 'assets/voice/delicious.mp3';
  static const doSomeMath = 'assets/voice/dosomemath.mp3';
  static const greatJob = 'assets/voice/greatjob.mp3';
  static const catchPaw = 'assets/voice/catchpaw.mp3';
  static const letsDrawing = 'assets/voice/letsdrawing.mp3';
}

/// Plays one voice prompt when the page enters the widget tree.
///
/// Voice prompts use their own player so existing answer and game sound effects
/// can continue to use [SoundFx] independently. A newer page always owns the
/// player, so disposal of the previous route cannot stop the new page's voice.
class PageVoice extends StatefulWidget {
  const PageVoice({
    super.key,
    required this.assetPath,
    required this.child,
    this.volume = 1,
  });

  final String assetPath;
  final Widget child;
  final double volume;

  @override
  State<PageVoice> createState() => _PageVoiceState();
}

class _PageVoiceState extends State<PageVoice> {
  late int _requestId;

  @override
  void initState() {
    super.initState();
    _requestId = PageVoicePlayer.instance.play(
      widget.assetPath,
      volume: widget.volume,
    );
  }

  @override
  void didUpdateWidget(PageVoice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath == widget.assetPath &&
        oldWidget.volume == widget.volume) {
      return;
    }
    PageVoicePlayer.instance.stop(_requestId);
    _requestId = PageVoicePlayer.instance.play(
      widget.assetPath,
      volume: widget.volume,
    );
  }

  @override
  void dispose() {
    PageVoicePlayer.instance.stop(_requestId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class PageVoicePlayer {
  PageVoicePlayer._();

  static final PageVoicePlayer instance = PageVoicePlayer._();

  final AudioPlayer _player = AudioPlayer();
  int _activeRequest = 0;

  int play(String assetPath, {double volume = 1}) {
    final requestId = ++_activeRequest;
    unawaited(_play(requestId, assetPath, volume.clamp(0.0, 1.0)));
    return requestId;
  }

  Future<void> _play(int requestId, String assetPath, double volume) async {
    try {
      await _player.stop();
      if (requestId != _activeRequest) return;

      await _player.setVolume(volume);
      if (requestId != _activeRequest) return;

      final source = assetPath.startsWith('assets/')
          ? assetPath.substring('assets/'.length)
          : assetPath;
      await _player.play(AssetSource(source));
    } catch (error, stackTrace) {
      debugPrint('PAGE VOICE ERROR ($assetPath): $error\n$stackTrace');
    }
  }

  void stop(int requestId) {
    if (requestId != _activeRequest) return;
    _activeRequest++;
    unawaited(_player.stop());
  }
}
