import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Reads the reward points stored on a user's profile document
/// (`users/{uid}.points`).
///
/// Points are *awarded* elsewhere (e.g. [ChatService.sendMessage] increments
/// the sender atomically with the message write); this service only exposes the
/// current total for display.
class UserPointsService {
  UserPointsService._();

  static final UserPointsService instance = UserPointsService._();

  /// Points granted to the sender for each check-in question they send.
  static const int pointsPerQuestion = 10;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<int>? _cachedStream;
  String? _cachedUid;

  /// Live stream of the signed-in user's point total. Emits 0 when signed out,
  /// when Firebase isn't ready, or before the `points` field exists.
  Stream<int> watchPoints() {
    final uid = _auth.currentUser?.uid;

    if (_cachedStream != null && _cachedUid == uid) {
      return _cachedStream!;
    }

    _cachedUid = uid;

    if (!_firebaseReady || uid == null) {
      _cachedStream = Stream<int>.value(0).asBroadcastStream();
    } else {
      _cachedStream = _db
          .collection('users')
          .doc(uid)
          .snapshots()
          .map((snapshot) => _pointsFrom(snapshot.data()))
          .asBroadcastStream();
    }

    return _cachedStream!;
  }

  int _pointsFrom(Map<String, dynamic>? data) {
    final raw = data?['points'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }
}
