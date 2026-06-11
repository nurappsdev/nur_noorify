import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:first_project/features/family/models/family_member.dart';
import 'package:first_project/features/family/models/family_request.dart';

/// Outcome of attempting to send a family request, so the UI can show the
/// right message without re-checking Firestore itself.
enum SendRequestResult {
  sent,
  selfRequest,
  alreadyRequested,
  alreadyFamily,
  notSignedIn,
  error,
}

/// Reads and writes the family-request flow.
///
/// Responsibilities are deliberately split with the backend:
///  * The client *creates* a pending request and *flips* its status to
///    accepted/declined (guarded by security rules so only the recipient can).
///  * The trusted Cloud Function is the only writer of
///    `users/{uid}.family_members`, and only when a request becomes accepted.
/// This guarantees a name can never land on a profile without acceptance.
class FamilyService {
  FamilyService._();

  static final FamilyService instance = FamilyService._();

  bool get _firebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('family_requests');

  /// Deterministic request id for a directed pair (requester -> recipient).
  String _pairId(String from, String to) => '${from}_$to';

  /// Sends a pending family request to [toUid]. Returns a [SendRequestResult]
  /// describing what happened; no `family_members` write occurs here.
  Future<SendRequestResult> sendRequest({
    required String toUid,
    required String toName,
    String? toPhoto,
  }) async {
    final me = currentUid;
    if (!_firebaseReady || me == null) return SendRequestResult.notSignedIn;
    if (me == toUid) return SendRequestResult.selfRequest;

    try {
      // Already in my accepted family list?
      final myDoc = await _users.doc(me).get();
      final members = (myDoc.data()?['family_members'] as List?) ?? const [];
      final alreadyFamily = members.any(
        (m) => m is Map && (m['uid'] ?? '').toString() == toUid,
      );
      if (alreadyFamily) return SendRequestResult.alreadyFamily;

      // An outstanding request already pending for this pair?
      final existing = await _requests.doc(_pairId(me, toUid)).get();
      final existingStatus = (existing.data()?['status'] ?? '').toString();
      if (existing.exists && existingStatus == 'pending') {
        return SendRequestResult.alreadyRequested;
      }

      final myData = myDoc.data() ?? const {};
      await _requests.doc(_pairId(me, toUid)).set({
        'from_uid': me,
        'from_name': (myData['display_name'] ?? '').toString(),
        'from_photo': (myData['photo_url'] ?? '').toString(),
        'to_uid': toUid,
        'to_name': toName,
        'to_photo': toPhoto ?? '',
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });
      return SendRequestResult.sent;
    } catch (_) {
      return SendRequestResult.error;
    }
  }

  /// Pending requests addressed to the signed-in user, newest first.
  ///
  /// Filtered to `pending` and sorted in memory so the query needs only the
  /// single-field auto index on `to_uid` (no composite index to deploy).
  Stream<List<FamilyRequest>> watchIncomingRequests() {
    final me = currentUid;
    if (!_firebaseReady || me == null) {
      return Stream<List<FamilyRequest>>.value(const []);
    }
    return _requests.where('to_uid', isEqualTo: me).snapshots().map((snap) {
      final list =
          snap.docs
              .map((d) => FamilyRequest.fromMap(d.id, d.data()))
              .where((r) => r.status == FamilyRequestStatus.pending)
              .toList()
            ..sort((a, b) {
              final at = a.createdAt;
              final bt = b.createdAt;
              if (at == null || bt == null) return 0;
              return bt.compareTo(at);
            });
      return list;
    });
  }

  /// Live count of pending incoming requests, for the badge.
  Stream<int> watchIncomingCount() =>
      watchIncomingRequests().map((list) => list.length);

  /// Recipient accepts a request. Only flips the status; the Cloud Function
  /// then adds this user to the requester's `family_members`.
  Future<void> accept(FamilyRequest request) async {
    if (!_firebaseReady) return;
    await _requests.doc(request.id).set({
      'status': 'accepted',
      'responded_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Recipient declines a request. Nothing is ever added to family_members.
  Future<void> decline(FamilyRequest request) async {
    if (!_firebaseReady) return;
    await _requests.doc(request.id).set({
      'status': 'declined',
      'responded_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// The signed-in user's accepted family members, shown on their profile.
  Stream<List<FamilyMember>> watchFamilyMembers() {
    final me = currentUid;
    if (!_firebaseReady || me == null) {
      return Stream<List<FamilyMember>>.value(const []);
    }
    return _users.doc(me).snapshots().map((snap) {
      final raw = (snap.data()?['family_members'] as List?) ?? const [];
      return raw
          .whereType<Map>()
          .map((m) => FamilyMember.fromMap(Map<String, dynamic>.from(m)))
          .where((m) => m.uid.isNotEmpty)
          .toList();
    });
  }
}
