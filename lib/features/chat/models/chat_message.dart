import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message inside a `chats/{chatId}/messages` subcollection.
///
/// In this app a message is a check-in *question*. The recipient may later
/// reply, which fills [answer]; until then the answer is considered pending.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.answer,
  });

  final String id;
  final String senderId;

  /// The question text.
  final String text;

  /// The recipient's reply. Null/empty means the answer is still pending.
  final String? answer;

  /// Null only for the brief window before the server timestamp resolves.
  final DateTime? createdAt;

  bool get isAnswered => (answer ?? '').trim().isNotEmpty;

  factory ChatMessage.fromMap(String id, Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    final ts = map['createdAt'];
    final reply = (map['answer'] ?? '').toString();
    return ChatMessage(
      id: id,
      senderId: (map['senderId'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      answer: reply.isEmpty ? null : reply,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
