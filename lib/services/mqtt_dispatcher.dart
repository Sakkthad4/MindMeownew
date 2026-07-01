import '../providers/cat_state.dart';
import '../audio/soundeffect.dart';

class MqttDispatcher {
  final CatState cat;

  MqttDispatcher(this.cat);

  void handle(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'touch':
        _onTouch(data);
        break;

      case 'emotion':
        _onEmotion(data);
        break;

      default:
        break;
    }
  }

  void _onTouch(Map<String, dynamic> data) {
    // ⭐ ตัดสินใจตรงนี้ ไม่ใช่ใน mqtt_service
    if (!cat.gameActive) return;

    cat.addXP(data['xp'] ?? 1);
    SoundFx.play(SoundFx.incorrect, volume: SoundFx.incorrectVolume);
  }

  void _onEmotion(Map<String, dynamic> data) {
    // handle emotion later
  }
}
