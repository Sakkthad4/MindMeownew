import 'package:flutter/material.dart';
import 'mindtalk_emotion.dart';
import '../app_language.dart';

Future<CatEmotion?> showCatEmotionPicker(BuildContext context) {
  return showDialog<CatEmotion>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(AppText.get('selectCatEmotion')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: CatEmotion.values.map((e) {
          return ListTile(
            title: Text(
              AppText.get(switch (e) {
                CatEmotion.calm => 'calm',
                CatEmotion.happy => 'happy',
                CatEmotion.sad => 'sad',
                CatEmotion.angry => 'angry',
              }),
            ),
            onTap: () => Navigator.pop(context, e),
          );
        }).toList(),
      ),
    ),
  );
}
