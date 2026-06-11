import 'package:cloud_firestore/cloud_firestore.dart';

enum FamilyRequestStatus { pending, accepted, declined, unknown }

FamilyRequestStatus _statusFrom(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'pending':
      return FamilyRequestStatus.pending;
    case 'accepted':
      return FamilyRequestStatus.accepted;
    case 'declined':
      return FamilyRequestStatus.declined;
    default:
      return FamilyRequestStatus.unknown;
  }
}

/// A family-member request document from the `family_requests` collection.
///
/// The document id is deterministic (`fromUid_toUid`) so a user cannot stack
/// duplicate pending requests against the same person. [fromUid] is the
/// requester (who tapped the leaderboard tile); [toUid] is the person who must
/// accept before they appear on the requester's profile.
class FamilyRequest {
  const FamilyRequest({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromPhoto,
    required this.toUid,
    required this.toName,
    required this.toPhoto,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String fromUid;
  final String fromName;
  final String? fromPhoto;
  final String toUid;
  final String toName;
  final String? toPhoto;
  final FamilyRequestStatus status;
  final DateTime? createdAt;

  String get resolvedFromName =>
      fromName.trim().isEmpty ? 'Noorify user' : fromName.trim();

  String get fromInitial {
    final source = resolvedFromName;
    return source.isEmpty ? '?' : source[0].toUpperCase();
  }

  factory FamilyRequest.fromMap(String id, Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    final created = map['created_at'];
    String? clean(Object? v) {
      final s = (v ?? '').toString().trim();
      return s.isEmpty ? null : s;
    }

    return FamilyRequest(
      id: id,
      fromUid: (map['from_uid'] ?? '').toString(),
      fromName: (map['from_name'] ?? '').toString(),
      fromPhoto: clean(map['from_photo']),
      toUid: (map['to_uid'] ?? '').toString(),
      toName: (map['to_name'] ?? '').toString(),
      toPhoto: clean(map['to_photo']),
      status: _statusFrom((map['status'] ?? '').toString()),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
