import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:first_project/features/family/models/family_relation.dart';

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
    required this.fromEmail,
    required this.toUid,
    required this.toName,
    required this.toPhoto,
    required this.toEmail,
    required this.status,
    required this.createdAt,
    this.relation,
  });

  final String id;
  final String fromUid;
  final String fromName;
  final String? fromPhoto;
  final String? fromEmail;
  final String toUid;
  final String toName;
  final String? toPhoto;
  final String? toEmail;
  final FamilyRequestStatus status;
  final DateTime? createdAt;

  /// Relationship the requester chose, from their point of view.
  final FamilyRelation? relation;

  /// Sender's name, falling back to the email handle (the app-wide convention)
  /// then a generic label — so an empty `from_name` never shows as a stranger.
  String get resolvedFromName {
    final name = fromName.trim();
    if (name.isNotEmpty) return name;
    final handle = (fromEmail ?? '').split('@').first.trim();
    if (handle.isNotEmpty) return handle;
    return 'Noorify user';
  }

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
      fromEmail: clean(map['from_email']),
      toUid: (map['to_uid'] ?? '').toString(),
      toName: (map['to_name'] ?? '').toString(),
      toPhoto: clean(map['to_photo']),
      toEmail: clean(map['to_email']),
      status: _statusFrom((map['status'] ?? '').toString()),
      createdAt: created is Timestamp ? created.toDate() : null,
      relation: familyRelationFromKey(map['relationship']?.toString()),
    );
  }
}
