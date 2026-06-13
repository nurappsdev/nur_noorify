import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:first_project/features/family/models/family_relation.dart';

/// One accepted family member, stored inside the requester's
/// `users/{uid}.family_members` array. The array is only ever written by the
/// trusted Cloud Function when a request reaches the `accepted` state, so a
/// member appearing here always corresponds to a request the person accepted.
class FamilyMember {
  const FamilyMember({
    required this.uid,
    required this.name,
    this.photoUrl,
    this.email,
    this.since,
    this.relation,
    this.inverse = false,
  });

  final String uid;
  final String name;
  final String? photoUrl;
  final String? email;
  final DateTime? since;

  /// How the requester related to this member (null for members saved before
  /// relationships existed).
  final FamilyRelation? relation;

  /// Whether this member is derived from a request the *other* person sent us
  /// (we are the recipient). When true the relationship is shown inverted —
  /// the requester who called us their father appears here as our child.
  final bool inverse;

  /// Relationship label from this user's point of view, inverting [relation]
  /// for members we received rather than sent. Null when no relation is known.
  String? relationLabel(bool isBangla) {
    final r = relation;
    if (r == null) return null;
    return inverse ? r.inverseLabel(isBangla) : r.label(isBangla);
  }

  /// Name to show, falling back to a generic label.
  String get resolvedName => name.trim().isEmpty ? 'Noorify user' : name.trim();

  /// First letter for the avatar placeholder.
  String get initial {
    final source = resolvedName;
    return source.isEmpty ? '?' : source[0].toUpperCase();
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    final since = map['since'];
    return FamilyMember(
      uid: (map['uid'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      photoUrl: () {
        final url = (map['photo_url'] ?? '').toString().trim();
        return url.isEmpty ? null : url;
      }(),
      email: () {
        final value = (map['email'] ?? '').toString().trim();
        return value.isEmpty ? null : value;
      }(),
      since: since is Timestamp ? since.toDate() : null,
      relation: familyRelationFromKey(map['relationship']?.toString()),
    );
  }
}
