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
  });

  final String uid;
  final String name;
  final String? photoUrl;
  final String? email;
  final DateTime? since;

  /// How the requester related to this member (null for members saved before
  /// relationships existed).
  final FamilyRelation? relation;

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
