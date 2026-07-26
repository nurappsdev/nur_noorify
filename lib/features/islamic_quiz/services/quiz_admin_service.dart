import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:first_project/core/utils/stream_utils.dart';
import 'package:first_project/features/islamic_quiz/models/quiz_question.dart';

/// A quiz question stored in Firestore (`quiz_questions`), created from the
/// admin panel. Bundled bank questions live in code; these are merged in when
/// a topic starts, so admins can publish new questions without an app release.
class RemoteQuizQuestion {
  const RemoteQuizQuestion({
    required this.id,
    required this.topic,
    required this.questionEn,
    required this.questionBn,
    required this.optionsEn,
    required this.optionsBn,
    required this.correctIndex,
    required this.active,
  });

  final String id;
  final QuizTopic topic;
  final String questionEn;
  final String questionBn;
  final List<String> optionsEn;
  final List<String> optionsBn;
  final int correctIndex;
  final bool active;

  static RemoteQuizQuestion? fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final topic = QuizAdminService.topicFromKey(
      (data['topic'] ?? '').toString(),
    );
    if (topic == null) return null;

    List<String> readOptions(String key) {
      final raw = data[key];
      if (raw is! Iterable) return const [];
      return raw.map((value) => value.toString()).toList();
    }

    final correctIndex = data['correct_index'];
    return RemoteQuizQuestion(
      id: doc.id,
      topic: topic,
      questionEn: (data['question_en'] ?? '').toString(),
      questionBn: (data['question_bn'] ?? '').toString(),
      optionsEn: readOptions('options_en'),
      optionsBn: readOptions('options_bn'),
      correctIndex: correctIndex is num ? correctIndex.toInt() : 0,
      active: data['active'] != false,
    );
  }

  /// Converts to the in-quiz model, falling back to the other language when
  /// one side was left empty in the editor.
  QuizQuestion toQuizQuestion() {
    final en = optionsEn.isNotEmpty ? optionsEn : optionsBn;
    final bn = optionsBn.isNotEmpty ? optionsBn : optionsEn;
    return QuizQuestion(
      questionEn: questionEn.isNotEmpty ? questionEn : questionBn,
      questionBn: questionBn.isNotEmpty ? questionBn : questionEn,
      optionsEn: en,
      optionsBn: bn,
      correctIndex: correctIndex,
    );
  }

  bool get isPlayable {
    final options = optionsEn.isNotEmpty ? optionsEn : optionsBn;
    return (questionEn.isNotEmpty || questionBn.isNotEmpty) &&
        options.length >= 2 &&
        correctIndex >= 0 &&
        correctIndex < options.length;
  }
}

class QuizAdminService {
  QuizAdminService._();

  static final QuizAdminService instance = QuizAdminService._();

  bool get _firebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('quiz_questions');

  static String topicKey(QuizTopic topic) {
    switch (topic) {
      case QuizTopic.quran:
        return 'quran';
      case QuizTopic.hadith:
        return 'hadith';
      case QuizTopic.elmNoor:
        return 'elm_noor';
      case QuizTopic.fiqh:
        return 'fiqh';
    }
  }

  static QuizTopic? topicFromKey(String key) {
    switch (key) {
      case 'quran':
        return QuizTopic.quran;
      case 'hadith':
        return QuizTopic.hadith;
      case 'elm_noor':
        return QuizTopic.elmNoor;
      case 'fiqh':
        return QuizTopic.fiqh;
    }
    return null;
  }

  /// Every stored question, newest first — for the admin panel list.
  Stream<List<RemoteQuizQuestion>> watchAllQuestions() {
    if (!_firebaseReady) {
      return broadcastValueStream(const <RemoteQuizQuestion>[]);
    }
    return _collection
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(RemoteQuizQuestion.fromDoc)
              .whereType<RemoteQuizQuestion>()
              .toList();
        });
  }

  /// Active, playable questions for one topic — merged into the bundled bank
  /// when the user starts a quiz. `active` is filtered client-side so the
  /// query needs no composite index.
  Future<List<QuizQuestion>> fetchActiveQuestions(QuizTopic topic) async {
    if (!_firebaseReady) return const [];
    final snapshot = await _collection
        .where('topic', isEqualTo: topicKey(topic))
        .get();
    return snapshot.docs
        .map(RemoteQuizQuestion.fromDoc)
        .whereType<RemoteQuizQuestion>()
        .where((question) => question.active && question.isPlayable)
        .map((question) => question.toQuizQuestion())
        .toList();
  }

  Future<String> upsertQuestion({
    String? id,
    required QuizTopic topic,
    required String questionEn,
    required String questionBn,
    required List<String> optionsEn,
    required List<String> optionsBn,
    required int correctIndex,
    required bool active,
  }) async {
    final payload = <String, dynamic>{
      'topic': topicKey(topic),
      'question_en': questionEn.trim(),
      'question_bn': questionBn.trim(),
      'options_en': optionsEn.map((option) => option.trim()).toList(),
      'options_bn': optionsBn.map((option) => option.trim()).toList(),
      'correct_index': correctIndex,
      'active': active,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (id == null) {
      payload['created_at'] = FieldValue.serverTimestamp();
      payload['created_by_uid'] = FirebaseAuth.instance.currentUser?.uid;
      final ref = await _collection.add(payload);
      return ref.id;
    }

    await _collection.doc(id).set(payload, SetOptions(merge: true));
    return id;
  }

  Future<void> setActive(String id, bool active) async {
    await _collection.doc(id).set({
      'active': active,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteQuestion(String id) async {
    await _collection.doc(id).delete();
  }
}
