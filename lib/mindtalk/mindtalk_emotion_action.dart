// mindtalk_emotion_action.dart
import 'mindtalk_emotion.dart';

extension CatEmotionMqtt on CatEmotion {
  String get eyeMode {
    switch (this) {
      case CatEmotion.happy:
        return 'eye_happy';
      case CatEmotion.sad:
        return 'eye_sad';
      case CatEmotion.angry:
        return 'eye_angry';
      case CatEmotion.calm:
        return 'eye_calm';
    }
  }
}
