import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:first_project/features/chat/models/chat_message.dart';
import 'package:first_project/features/chat/models/chat_user.dart';

/// Thrown by [ChatService.sendMessage] when the same check-in question has
/// already been sent in this conversation today. Each question may be sent at
/// most once per calendar day.
class QuestionAlreadySentTodayException implements Exception {
  const QuestionAlreadySentTodayException();
}

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  bool get _firebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  String? get currentUid => _auth.currentUser?.uid;

  /// Deterministic chat document id for a pair of users. Sorting the two uids
  /// guarantees both participants resolve to the same document regardless of
  /// who opens the conversation first.
  String chatIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Live stream of every registered user except the signed-in one,
  /// sorted by display name.
  Stream<List<ChatUser>> watchUsers() {
    if (!_firebaseReady) return Stream<List<ChatUser>>.value(const []);

    return _users.snapshots().map((snapshot) {
      final me = currentUid;
      final users = snapshot.docs
          .where((doc) => doc.id != me)
          .map((doc) => ChatUser.fromMap(doc.id, doc.data()))
          .toList();

      users.sort(
        (a, b) =>
            a.resolvedName.toLowerCase().compareTo(b.resolvedName.toLowerCase()),
      );
      return users;
    });
  }

  /// Live stream of the conversation with [otherUid], newest message first.
  Stream<List<ChatMessage>> watchMessages(String otherUid) {
    final me = currentUid;
    if (me == null || !_firebaseReady) {
      return Stream<List<ChatMessage>>.value(const []);
    }

    return _chats
        .doc(chatIdFor(me, otherUid))
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Sends [text] to [otherUid]. Writes the message and updates the parent
  /// chat summary atomically so the conversation list stays in sync.
  ///
  /// The message is stored as a question with a pending (null) answer; the
  /// recipient can fill it in later.
  ///
  /// A given question may only be sent once per calendar day in a conversation.
  /// If the same question has already been sent today, this throws a
  /// [QuestionAlreadySentTodayException] without writing anything.
  Future<void> sendMessage({
    required String otherUid,
    required String text,
  }) async {
    final me = currentUid;
    final trimmed = text.trim();
    if (me == null || !_firebaseReady || trimmed.isEmpty) return;

    final chatRef = _chats.doc(chatIdFor(me, otherUid));

    // Guard against sending the same question twice on the same day.
    if (await _sentToday(chatRef, trimmed)) {
      throw const QuestionAlreadySentTodayException();
    }

    final batch = _db.batch();

    batch.set(chatRef.collection('messages').doc(), {
      'senderId': me,
      'text': trimmed,
      'answer': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(chatRef, {
      'participants': [me, otherUid]..sort(),
      'lastMessage': trimmed,
      'lastSenderId': me,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Whether a question equal to [text] has already been sent in [chatRef]
  /// since local midnight. Filters by [text] in memory so the query only needs
  /// the single-field `createdAt` index.
  Future<bool> _sentToday(
    DocumentReference<Map<String, dynamic>> chatRef,
    String text,
  ) async {
    final now = DateTime.now();
    final startOfDay = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day),
    );

    final todays = await chatRef
        .collection('messages')
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .get();

    return todays.docs.any(
      (doc) => (doc.data()['text'] ?? '').toString() == text,
    );
  }

  /// Records the recipient's Yes/No [answer] to a question [messageId].
  /// Only the user who did *not* send the question should call this.
  Future<void> answerMessage({
    required String otherUid,
    required String messageId,
    required String answer,
  }) async {
    final me = currentUid;
    if (me == null || !_firebaseReady) return;

    await _chats
        .doc(chatIdFor(me, otherUid))
        .collection('messages')
        .doc(messageId)
        .set({
          'answer': answer,
          'answeredBy': me,
          'answeredAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
