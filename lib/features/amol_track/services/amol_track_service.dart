import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:first_project/features/amol_track/models/amol_track_models.dart';

/// Persists which deeds the user has marked done, keyed by calendar date.
///
/// When the user is signed in, the source of truth is Firestore at
/// `users/{uid}/amol_track/{yyyy-MM-dd}`, where each document holds
/// `{ ids: [...], score: int, date: 'yyyy-MM-dd', updatedAt }`. A live snapshot
/// keeps the in-memory store (and so every Amol view: the home card, today's
/// list, and the weekly/monthly trends) in sync across devices in real time.
///
/// A local JSON mirror (via [DefaultCacheManager]) is kept for offline paint and
/// for signed-out usage, so the tracker still works with no network or account.
///
/// This is a process-wide singleton: the tracker screen and the home card share
/// one in-memory store, so a toggle on either is reflected on the other in real
/// time via [revision].
class AmolTrackService {
  AmolTrackService._();

  static final AmolTrackService _instance = AmolTrackService._();

  factory AmolTrackService() => _instance;

  static const _cacheKey = 'amol_track_v1';

  final BaseCacheManager _cache = DefaultCacheManager();

  /// `dateKey -> set of completed item ids`.
  final Map<String, Set<String>> _byDate = {};
  bool _loaded = false;

  /// Bumped on every change so listeners (e.g. the home card) can rebuild.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  bool get _firebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  String? get _uid => _firebaseReady ? _auth.currentUser?.uid : null;

  /// The signed-in user's dated amol documents, or null when signed out.
  CollectionReference<Map<String, dynamic>>? _userCollection() {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('amol_track');
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteSub;
  StreamSubscription<User?>? _authSub;
  String? _boundUid;

  /// Normalises a [DateTime] to a stable `yyyy-MM-dd` storage key. The format is
  /// chosen so that document ids sort chronologically (used for trends).
  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Loads the local mirror for an instant first paint, then (if signed in)
  /// binds to Firestore as the source of truth. Safe to call repeatedly.
  Future<void> load() async {
    if (!_loaded) {
      await _loadLocal();
      _loaded = true;
    }
    _bindAuth();
    await _attachRemote();
  }

  Future<void> _loadLocal() async {
    try {
      final cached = await _cache.getFileFromCache(_cacheKey);
      if (cached != null && await cached.file.exists()) {
        final raw = await cached.file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (value is List) {
              _byDate[key.toString()] =
                  value.map((e) => e.toString()).toSet();
            }
          });
        }
      }
    } catch (_) {
      // Ignore corrupted local data and start fresh.
    }
  }

  /// Re-binds the remote sync whenever the signed-in user changes, so signing
  /// in/out swaps the data source without an app restart.
  void _bindAuth() {
    if (!_firebaseReady || _authSub != null) return;
    _authSub = _auth.authStateChanges().listen((_) {
      unawaited(_attachRemote());
    });
  }

  /// Connects the in-memory store to the current user's Firestore documents.
  /// On sign-out it detaches and clears that user's data; on sign-in (or a
  /// switch) it rebuilds from the cloud and listens for live changes.
  Future<void> _attachRemote() async {
    final col = _userCollection();
    final uid = _uid;

    if (col == null || uid == null) {
      // Signed out: stop syncing and drop the previous user's data.
      await _remoteSub?.cancel();
      _remoteSub = null;
      if (_boundUid != null) {
        _boundUid = null;
        _byDate.clear();
        await _clearLocal();
        revision.value++;
      }
      return;
    }

    if (_boundUid == uid && _remoteSub != null) return;

    await _remoteSub?.cancel();
    // Switching accounts must not leak the previous user's deeds.
    if (_boundUid != uid) _byDate.clear();
    _boundUid = uid;

    try {
      final snap = await col.get();
      _applyDocs(snap.docs);
      await _persist();
      revision.value++;
    } catch (_) {
      // Offline or transient failure — the listener below recovers once the
      // connection returns; the local mirror keeps the UI populated meanwhile.
    }

    _remoteSub = col.snapshots().listen((snap) {
      _applyDocs(snap.docs);
      unawaited(_persist());
      revision.value++;
    });
  }

  /// Rebuilds the in-memory store from a full collection snapshot.
  void _applyDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    _byDate.clear();
    for (final doc in docs) {
      final raw = doc.data()['ids'];
      if (raw is! List) continue;
      final ids = raw.map((e) => e.toString()).toSet();
      if (ids.isNotEmpty) _byDate[doc.id] = ids;
    }
  }

  /// The set of completed item ids for [date] (empty if none recorded).
  Set<String> completedFor(DateTime date) =>
      Set<String>.from(_byDate[dateKey(date)] ?? const <String>{});

  /// Count of completed deeds for [date].
  int completedCountFor(DateTime date) => _byDate[dateKey(date)]?.length ?? 0;

  /// Weighted score for [date] — the sum of the weights of every deed marked
  /// done that day (0..[kAmolMaxScore]).
  int scoreFor(DateTime date) =>
      amolScoreForIds(_byDate[dateKey(date)] ?? const <String>{});

  /// Flips the done state of [itemId] on [date] and persists the change to the
  /// local mirror and (when signed in) Firestore.
  Future<bool> toggle(DateTime date, String itemId) async {
    final key = dateKey(date);
    final set = _byDate.putIfAbsent(key, () => <String>{});
    final nowDone = !set.remove(itemId);
    if (nowDone) set.add(itemId);
    final cleared = set.isEmpty;
    final ids = cleared ? const <String>{} : Set<String>.from(set);
    if (cleared) _byDate.remove(key);
    revision.value++;
    await _persist();

    final col = _userCollection();
    if (col != null) {
      try {
        if (cleared) {
          await col.doc(key).delete();
        } else {
          await col.doc(key).set(_docFor(key, ids));
        }
      } catch (_) {
        // Firestore's offline queue will replay the write when back online.
      }
    }
    return nowDone;
  }

  Map<String, dynamic> _docFor(String key, Set<String> ids) => {
        'ids': ids.toList(),
        'score': amolScoreForIds(ids),
        'date': key,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Future<void> _persist() async {
    final payload = <String, dynamic>{
      for (final entry in _byDate.entries) entry.key: entry.value.toList(),
    };
    await _cache.putFile(
      _cacheKey,
      Uint8List.fromList(utf8.encode(jsonEncode(payload))),
      key: _cacheKey,
      fileExtension: 'json',
    );
  }

  Future<void> _clearLocal() async {
    try {
      await _cache.removeFile(_cacheKey);
    } catch (_) {
      // Nothing cached yet — fine.
    }
  }
}
