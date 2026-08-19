import 'dart:async';

import '../providers/cat_state.dart';
import '../ble/robot_ble_service.dart';

late CatState _cat;

void initGameLogic(CatState cat) {
  _cat = cat;
}

void onGameWin() {
  _cat.endGame(); // ⭐⭐ สำคัญมาก

  unawaited(_sendRobotWinFeedback());

  playMp3("assets/effects/game_win.mp3");
}

Future<void> _sendRobotWinFeedback() async {
  final ble = RobotBleService.I;
  if (!ble.isConnected) return;
  try {
    await ble.setEyeMode('heart');
    await ble.wagTail();
  } catch (_) {
    // Game flow stays independent from a transient BLE disconnection.
  }
}

void playMp3(String name) {
  print("▶ PLAY $name");
}
