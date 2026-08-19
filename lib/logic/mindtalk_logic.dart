import 'dart:async';

import '../ble/robot_ble_service.dart';
import '../providers/cat_state.dart';

void onMindTalkResponse(String intent, CatState cat) {
  switch (intent) {
    case 'happy':
      cat.setEmotion(CatEmotion.happy);
      sendEmotion('happy');
      playMp3('happy.mp3');
      break;

    case 'sad':
      cat.setEmotion(CatEmotion.sad);
      sendEmotion('sad');
      playMp3('sad.mp3');
      break;

    case 'angry':
      cat.setEmotion(CatEmotion.angry);
      sendEmotion('angry');
      playMp3('angry.mp3');
      break;

    default:
      cat.setEmotion(CatEmotion.calm);
      sendEmotion('calm');
      playMp3('calm.mp3');
  }
}

void sendEmotion(String mode) {
  final ble = RobotBleService.I;
  if (!ble.isConnected) return;

  final eyeMode = switch (mode) {
    'happy' => 'heart',
    'angry' => 'red',
    _ => 'normal',
  };
  unawaited(ble.setEyeMode(eyeMode).catchError((Object _) {}));
}

void playMp3(String name) {
  print("▶ PLAY $name");
}
