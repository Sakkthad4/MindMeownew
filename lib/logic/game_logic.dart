import 'dart:async';

import '../providers/cat_state.dart';
import '../ble/robot_celebration.dart';

late CatState _cat;

void initGameLogic(CatState cat) {
  _cat = cat;
}

void onGameWin() {
  _cat.endGame(); // ⭐⭐ สำคัญมาก

  unawaited(RobotCelebrationController.instance.celebrate());

  playMp3("assets/effects/game_win.mp3");
}

void playMp3(String name) {
  print("▶ PLAY $name");
}
