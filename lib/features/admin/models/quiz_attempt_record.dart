import 'package:cloud_firestore/cloud_firestore.dart';

/// One row from a `users/{uid}/quiz_attempts/{attemptId}` document — a
/// finished Elm Noor quiz attempt, for the admin panel's Leaderboard
/// Management tab. Logged for monitoring only; it never affects points.
class QuizAttemptRecord {
  const QuizAttemptRecord({
    required this.uid,
    required this.topic,
    required this.correct,
    required this.total,
    required this.sessionPoints,
    required this.createdAt,
  });

  final String uid;
  final String topic;
  final int correct;
  final int total;
  final int sessionPoints;
  final DateTime? createdAt;

  double get accuracy => total <= 0 ? 0 : correct / total;

  factory QuizAttemptRecord.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawCorrect = data['correct'];
    final rawTotal = data['total'];
    final rawPoints = data['session_points'];
    final rawCreatedAt = data['created_at'];
    return QuizAttemptRecord(
      uid: doc.reference.parent.parent?.id ?? '',
      topic: (data['topic'] ?? '').toString(),
      correct: rawCorrect is num ? rawCorrect.toInt() : 0,
      total: rawTotal is num ? rawTotal.toInt() : 0,
      sessionPoints: rawPoints is num ? rawPoints.toInt() : 0,
      createdAt: rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null,
    );
  }
}
