import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:first_project/core/utils/stream_utils.dart';
import 'package:first_project/features/admin/models/points_history_entry.dart';
import 'package:first_project/features/admin/models/quiz_attempt_record.dart';
import 'package:first_project/features/leaderboard/models/leaderboard_entry.dart';
import 'package:first_project/features/leaderboard/services/leaderboard_service.dart';

/// Backs the admin panel's Leaderboard Management tab: rankings (delegated
/// to [LeaderboardService]), plus the point-history and quiz-attempt logs
/// collected across every user via `collectionGroup` queries.
class LeaderboardAdminService {
  LeaderboardAdminService._();

  static final LeaderboardAdminService instance = LeaderboardAdminService._();

  bool get _firebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Same ranked list shown on the user-facing leaderboard screen.
  Stream<List<LeaderboardEntry>> watchRankings() =>
      LeaderboardService.instance.watchLeaderboard();

  /// Most recent point-earning events across all users, newest first.
  Stream<List<PointsHistoryEntry>> watchPointsHistory({int limit = 100}) {
    if (!_firebaseReady) {
      return broadcastValueStream(const <PointsHistoryEntry>[]);
    }
    return _db
        .collectionGroup('points_history')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(PointsHistoryEntry.fromDoc).toList(),
        );
  }

  /// Most recent Elm Noor quiz attempts across all users, newest first.
  Stream<List<QuizAttemptRecord>> watchQuizAttempts({int limit = 200}) {
    if (!_firebaseReady) {
      return broadcastValueStream(const <QuizAttemptRecord>[]);
    }
    return _db
        .collectionGroup('quiz_attempts')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(QuizAttemptRecord.fromDoc).toList(),
        );
  }
}
