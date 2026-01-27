// lib/models/chat_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderUid;
  final String text;
  final Timestamp? createdAt;

  ChatMessage({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>? ?? {});
    return ChatMessage(
      id: doc.id,
      senderUid: (d['senderUid'] ?? '').toString(),
      text: (d['text'] ?? '').toString(),
      createdAt: d['createdAt'] as Timestamp?,
    );
  }
}
