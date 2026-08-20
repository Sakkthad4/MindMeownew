import 'dart:async';

import 'providers/cat_state.dart';
import 'ble/robot_celebration.dart';
import 'audio/soundeffect.dart';

late CatState _cat;

void initGameLogic(CatState cat) {
  _cat = cat;
}

void onGameWin() {
  _cat.endGame();

  unawaited(RobotCelebrationController.instance.celebrate());

  SoundFx.winFx();
}
