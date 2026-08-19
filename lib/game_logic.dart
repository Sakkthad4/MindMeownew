import 'dart:async';

import 'providers/cat_state.dart';
import 'ble/robot_ble_service.dart';
import 'audio/soundeffect.dart';

late CatState _cat;

void initGameLogic(CatState cat) {
  _cat = cat;
}

void onGameWin() {
  _cat.endGame();

  unawaited(_sendRobotWinFeedback());

  SoundFx.winFx();
}

Future<void> _sendRobotWinFeedback() async {
  final ble = RobotBleService.I;
  if (!ble.isConnected) return;
  try {
    await ble.setEyeMode('heart');
    await ble.wagTail();
  } catch (_) {
    // Winning a game must still complete if the robot disconnects mid-command.
  }
}
