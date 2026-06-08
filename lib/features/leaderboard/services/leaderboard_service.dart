import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:first_project/features/leaderboard/models/leaderboard_entry.dart';

class LeaderboardService {
  LeaderboardService._();

  static final LeaderboardService instance = LeaderboardService._();

  bool get _firebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// The signed-in user's uid, so the screen can highlight their own row.
  String? get currentUid => _auth.currentUser?.uid;

  /// Live stream of every registered user, ranked by points (highest first).
  ///
  /// Sorting is done client-side rather than via `orderBy('points')` so that
  /// users who have not earned any points yet (no `points` field) are still
  /// listed, treated as zero. Ties break alphabetically by name.
  Stream<List<LeaderboardEntry>> watchLeaderboard() {
    if (!_firebaseReady) {
      return Stream<List<LeaderboardEntry>>.value(const []);
    }

    return _db.collection('users').snapshots().map((snapshot) {
      final entries = snapshot.docs
          .map((doc) => LeaderboardEntry.fromMap(doc.id, doc.data()))
          .toList();

      entries.sort((a, b) {
        final byPoints = b.points.compareTo(a.points);
        if (byPoints != 0) return byPoints;
        return a.resolvedName.toLowerCase().compareTo(
          b.resolvedName.toLowerCase(),
        );
      });
      return entries;
    });
  }
}
