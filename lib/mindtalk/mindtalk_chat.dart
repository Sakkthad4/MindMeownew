import 'package:flutter/material.dart';

class ChatMessage {
  final bool isBot;
  final String text;
  ChatMessage({required this.isBot, required this.text});
}

class MindTalkChatView extends StatelessWidget {
  final List<ChatMessage> messages;
  const MindTalkChatView({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final m = messages[i];
        return Align(
          alignment: m.isBot ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: m.isBot ? const Color(0xFFFFA726) : const Color(0xFF42A5F5),
                width: 4,
              ),
            ),
            child: Text(
              m.text,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}
