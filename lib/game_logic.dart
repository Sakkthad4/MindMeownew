import '../providers/cat_state.dart';
import '../services/mqtt_service.dart';
import '../audio/soundeffect.dart';

late CatState _cat;

void initGameLogic(CatState cat) {
  _cat = cat;
}

void onGameWin() {
  _cat.endGame();

  MqttService.I.send({"type": "eye", "mode": "heart"});
  MqttService.I.send({"type": "tail", "action": "wag"});

  SoundFx.winFx();
}
