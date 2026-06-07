import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message inside a `chats/{chatId}/messages` subcollection.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;

  /// Null only for the brief window before the server timestamp resolves.
  final DateTime? createdAt;

  factory ChatMessage.fromMap(String id, Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    final ts = map['createdAt'];
    return ChatMessage(
      id: id,
      senderId: (map['senderId'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
