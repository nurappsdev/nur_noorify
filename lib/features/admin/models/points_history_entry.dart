import 'package:cloud_firestore/cloud_firestore.dart';

/// One row from a `users/{uid}/points_history/{eventId}` document — a single
/// point award, for the admin panel's Leaderboard Management tab.
class PointsHistoryEntry {
  const PointsHistoryEntry({
    required this.uid,
    required this.source,
    required this.amount,
    required this.createdAt,
  });

  final String uid;
  final String source;
  final int amount;
  final DateTime? createdAt;

  /// Human-readable label for [source] (e.g. `chat_checkin`).
  String get sourceLabel {
    switch (source) {
      case 'chat_checkin':
        return 'Chat check-in';
      default:
        return source;
    }
  }

  factory PointsHistoryEntry.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawAmount = data['amount'];
    final rawCreatedAt = data['created_at'];
    return PointsHistoryEntry(
      uid: doc.reference.parent.parent?.id ?? '',
      source: (data['source'] ?? '').toString(),
      amount: rawAmount is num ? rawAmount.toInt() : 0,
      createdAt: rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null,
    );
  }
}
