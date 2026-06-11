import 'package:cloud_firestore/cloud_firestore.dart';

/// One accepted family member, stored inside the requester's
/// `users/{uid}.family_members` array. The array is only ever written by the
/// trusted Cloud Function when a request reaches the `accepted` state, so a
/// member appearing here always corresponds to a request the person accepted.
class FamilyMember {
  const FamilyMember({
    required this.uid,
    required this.name,
    this.photoUrl,
    this.since,
  });

  final String uid;
  final String name;
  final String? photoUrl;
  final DateTime? since;

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
      since: since is Timestamp ? since.toDate() : null,
    );
  }
}
