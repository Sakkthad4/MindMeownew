import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test22/mindtalk/mindtalk_ai_service.dart';
import 'package:flutter_test22/mindtalk/mindtalk_audio_router.dart';
import 'package:flutter_test22/mindtalk/mindtalk_language.dart';

void main() {
  test('fixed replies use the same language as the user', () {
    final router = MindTalkAudioRouter();

    expect(router.tryRoute('ขอบคุณมาก')!.replyText, contains('ยินดี'));
    expect(router.tryRoute('Thank you')!.replyText, contains("You're welcome"));
    expect(router.tryRoute('谢谢你')!.replyText, contains('不客气'));
  });

  test(
    'AI request uses system instruction, history, and selected language',
    () async {
      late Map<String, dynamic> requestBody;
      final client = MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': '**สวัสดีค่ะ**   วันนี้สบายดีไหมคะ'},
                    ],
                  },
                },
              ],
            }),
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final service = MindTalkAiService(client: client, apiKey: 'test-key');

      final reply = await service.reply(
        userText: 'วันนี้เหนื่อย',
        language: SpeechLang.th,
        history: [
          (isUser: false, text: 'ข้อความทักทาย'),
          (isUser: true, text: 'เมื่อวานนอนไม่พอ'),
          (isUser: false, text: 'พักผ่อนให้เพียงพอนะคะ'),
        ],
      );

      expect(requestBody['systemInstruction'], isNotNull);
      expect(jsonEncode(requestBody['contents']), contains('Reply in Thai'));
      expect(reply, 'สวัสดีค่ะ วันนี้สบายดีไหมคะ');
    },
  );
}
