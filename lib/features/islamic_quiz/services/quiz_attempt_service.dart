import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:first_project/features/islamic_quiz/models/quiz_question.dart';

/// Records finished Elm Noor quiz attempts to
/// `users/{uid}/quiz_attempts/{attemptId}` for admin monitoring.
///
/// Attempts are logged for visibility only — they do not affect
/// `users/{uid}.points` or the leaderboard.
class QuizAttemptService {
  QuizAttemptService._();

  static final QuizAttemptService instance = QuizAttemptService._();

  bool get _firebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<void> recordAttempt({
    required QuizTopic topic,
    required int correct,
    required int total,
    required int sessionPoints,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (!_firebaseReady || uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('quiz_attempts')
        .add({
          'topic': topic.name,
          'correct': correct,
          'total': total,
          'session_points': sessionPoints,
          'created_at': FieldValue.serverTimestamp(),
        });
  }
}
