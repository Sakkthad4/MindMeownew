import '../services/mqtt_service.dart';
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
  MqttService.I.send({
    "type": "eye",
    "mode": mode,
  });
}

void playMp3(String name) {
  print("▶ PLAY $name");
}
