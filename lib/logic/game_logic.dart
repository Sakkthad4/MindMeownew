import '../providers/cat_state.dart';
import '../services/mqtt_service.dart';

late CatState _cat;


void initGameLogic(CatState cat) {
  _cat = cat;
}

void onGameWin() {
  _cat.endGame(); // ⭐⭐ สำคัญมาก

  MqttService.I.send({
    "type": "eye",
    "mode": "heart",
  });

  MqttService.I.send({
    "type": "tail",
    "action": "wag",
  });

  playMp3("assets/effects/game_win.mp3");
}

void playMp3(String name) {
  print("▶ PLAY $name");
}
