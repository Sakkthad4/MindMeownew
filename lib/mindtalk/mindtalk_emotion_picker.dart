import 'package:flutter/material.dart';
import 'mindtalk_emotion.dart';

Future<CatEmotion?> showCatEmotionPicker(BuildContext context) {
  return showDialog<CatEmotion>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('เลือกอารมณ์แมว'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: CatEmotion.values.map((e) {
          return ListTile(
            title: Text(e.labelTH),
            onTap: () => Navigator.pop(context, e),
          );
        }).toList(),
      ),
    ),
  );
}
