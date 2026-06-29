import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:first_project/features/family/models/family_member.dart';
import 'package:first_project/features/family/models/family_relation.dart';
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
    required FamilyRelation relation,
    String? toPhoto,
    String? toEmail,
  }) async {
    final me = currentUid;
    if (!_firebaseReady || me == null) return SendRequestResult.notSignedIn;
    if (me == toUid) return SendRequestResult.selfRequest;

    try {
      // A request in either direction settles the relationship: if one was
      // accepted the two are already family (so no reverse request), and if one
      // is still pending a request is already outstanding between them. This is
      // what stops user B from re-adding user A after A added B.
      final outgoing = await _requests.doc(_pairId(me, toUid)).get();
      final incoming = await _requests.doc(_pairId(toUid, me)).get();
      String statusOf(DocumentSnapshot<Map<String, dynamic>> d) =>
          (d.data()?['status'] ?? '').toString();
      final statuses = {statusOf(outgoing), statusOf(incoming)};
      if (statuses.contains('accepted')) {
        return SendRequestResult.alreadyFamily;
      }
      if (statuses.contains('pending')) {
        return SendRequestResult.alreadyRequested;
      }

      final myDoc = await _users.doc(me).get();
      final myData = myDoc.data() ?? const {};
      final myEmail = (myData['email'] ?? '').toString().trim();
      final myName = (myData['display_name'] ?? '').toString().trim();
      // Mirror the app-wide name convention: display name, else email handle.
      final fromName = myName.isNotEmpty ? myName : myEmail.split('@').first;
      await _requests.doc(_pairId(me, toUid)).set({
        'from_uid': me,
        'from_name': fromName,
        'from_photo': (myData['photo_url'] ?? '').toString(),
        'from_email': myEmail,
        'to_uid': toUid,
        'to_name': toName,
        'to_photo': toPhoto ?? '',
        'to_email': toEmail ?? '',
        'relationship': relation.key,
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

  /// Requests the signed-in user has *sent*, newest first, in every status.
  ///
  /// Lets the profile show each outgoing request with its current status
  /// (pending / accepted / declined). Sorted in memory so the query needs only
  /// the single-field auto index on `from_uid`.
  Stream<List<FamilyRequest>> watchOutgoingRequests() {
    final me = currentUid;
    if (!_firebaseReady || me == null) {
      return Stream<List<FamilyRequest>>.value(const []);
    }
    return _requests.where('from_uid', isEqualTo: me).snapshots().map((snap) {
      final list =
          snap.docs.map((d) => FamilyRequest.fromMap(d.id, d.data())).toList()
            ..sort((a, b) {
              final at = a.createdAt;
              final bt = b.createdAt;
              if (at == null || bt == null) return 0;
              return bt.compareTo(at);
            });
      return list;
    });
  }

  /// Forces a server round-trip for both request streams, for pull-to-refresh.
  /// The active snapshot listeners pick up anything new; awaiting the gets keeps
  /// the refresh indicator visible until the fetch actually completes.
  Future<void> refreshFamilyData() async {
    final me = currentUid;
    if (!_firebaseReady || me == null) return;
    const serverFirst = GetOptions(source: Source.server);
    try {
      await Future.wait([
        _requests.where('to_uid', isEqualTo: me).get(serverFirst),
        _requests.where('from_uid', isEqualTo: me).get(serverFirst),
      ]);
    } catch (_) {
      // Offline or transient error: the live streams keep the last good data.
    }
  }

  /// Recipient accepts a request. Flipping the status to `accepted` is all
  /// that's needed: the requester's family list is derived from their accepted
  /// requests (see [watchFamilyMembers]).
  Future<void> accept(FamilyRequest request) async {
    if (!_firebaseReady) return;
    await _requests.doc(request.id).set({
      'status': 'accepted',
      'responded_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Recipient declines a request. A declined request is never counted as a
  /// family member.
  Future<void> decline(FamilyRequest request) async {
    if (!_firebaseReady) return;
    await _requests.doc(request.id).set({
      'status': 'declined',
      'responded_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// The signed-in user's accepted family members, shown on their profile.
  ///
  /// Combines both directions of an accepted request, so the relationship is
  /// reflected on *both* profiles:
  ///  * requests this user sent (`from_uid == me`) — the other person appears
  ///    with the relation this user chose (e.g. "Father");
  ///  * requests this user received (`to_uid == me`) — the requester appears
  ///    with the inverted relation (whoever called us their father appears as
  ///    our "Child").
  /// No Cloud Function or `family_members` array is needed: a name can still
  /// never appear without acceptance, because only the recipient can flip a
  /// request to `accepted` (enforced by the `family_requests` update rule).
  Stream<List<FamilyMember>> watchFamilyMembers() {
    final me = currentUid;
    if (!_firebaseReady || me == null) {
      return Stream<List<FamilyMember>>.value(const []);
    }

    // Stream.multi with isBroadcast runs this setup fresh for each listener,
    // matching Firestore's own snapshots(). A single-subscription controller
    // would throw "Stream has already been listened to" when a StreamBuilder
    // re-subscribes (e.g. when its list sliver is recycled on scroll).
    return Stream.multi((controller) {
      var sent = const <FamilyMember>[];
      var received = const <FamilyMember>[];
      var sentReady = false;
      var receivedReady = false;

      void emit() {
        if (!sentReady && !receivedReady) return;
        controller.add(<FamilyMember>[...sent, ...received]);
      }

      final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[
        _requests.where('from_uid', isEqualTo: me).snapshots().listen((snap) {
          sent = _acceptedMembers(snap, asRecipient: false);
          sentReady = true;
          emit();
        }, onError: controller.addError),
        _requests.where('to_uid', isEqualTo: me).snapshots().listen((snap) {
          received = _acceptedMembers(snap, asRecipient: true);
          receivedReady = true;
          emit();
        }, onError: controller.addError),
      ];

      controller.onCancel = () async {
        for (final s in subs) {
          await s.cancel();
        }
      };
    }, isBroadcast: true);
  }

  /// Maps a request snapshot to accepted [FamilyMember]s. When [asRecipient] is
  /// true the snapshot holds requests addressed to us, so the member is the
  /// *sender* and the relationship is inverted; otherwise it is the recipient
  /// of requests we sent.
  List<FamilyMember> _acceptedMembers(
    QuerySnapshot<Map<String, dynamic>> snap, {
    required bool asRecipient,
  }) {
    return snap.docs
        .map((d) => FamilyRequest.fromMap(d.id, d.data()))
        .where((r) => r.status == FamilyRequestStatus.accepted)
        .map(
          (r) => asRecipient
              ? FamilyMember(
                  uid: r.fromUid,
                  name: r.resolvedFromName,
                  photoUrl: r.fromPhoto,
                  email: r.fromEmail,
                  since: r.createdAt,
                  relation: r.relation,
                  inverse: true,
                )
              : FamilyMember(
                  uid: r.toUid,
                  name: r.toName,
                  photoUrl: r.toPhoto,
                  email: r.toEmail,
                  since: r.createdAt,
                  relation: r.relation,
                ),
        )
        .where((m) => m.uid.isNotEmpty)
        .toList();
  }
}
