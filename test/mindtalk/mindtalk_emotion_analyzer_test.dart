import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test22/healthcare/models/mindtalk_emotion_event.dart';
import 'package:flutter_test22/mindtalk/mindtalk_emotion_analyzer.dart';

void main() {
  const analyzer = MindTalkEmotionAnalyzer();

  test('detects anxiety from recent Thai conversation', () {
    final result = analyzer.analyze([
      'วันนี้งานเยอะ',
      'รู้สึกเครียดและกังวลว่าจะทำไม่ทัน',
    ]);
    expect(result.emotion, MindTalkEmotion.anxious);
    expect(result.confidence, greaterThan(0.5));
  });

  test('detects sadness from English conversation', () {
    final result = analyzer.analyze(['I feel lonely and sad today']);
    expect(result.emotion, MindTalkEmotion.sad);
  });

  test('detects happiness from Chinese conversation', () {
    final result = analyzer.analyze(['今天很开心，谢谢你']);
    expect(result.emotion, MindTalkEmotion.happy);
  });

  test('returns neutral without an emotional signal', () {
    final result = analyzer.analyze(['วันนี้ฉันกินข้าวตอนเที่ยง']);
    expect(result.emotion, MindTalkEmotion.neutral);
  });
}
