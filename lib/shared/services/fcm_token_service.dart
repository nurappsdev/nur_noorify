import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Keeps the signed-in user's FCM device tokens in `users/{uid}.fcm_tokens`
/// so the Cloud Function can deliver targeted pushes (e.g. family requests).
///
/// Tokens are stored as an array because one account may be signed in on
/// several devices. Stale tokens are pruned server-side by the function when a
/// send fails with a not-registered error.
class FcmTokenService {
  FcmTokenService._();

  static final FcmTokenService instance = FcmTokenService._();

  bool get _firebaseReady => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Fetches the current device token and links it to the signed-in user.
  /// Safe to call after every successful sign-in.
  Future<void> registerCurrentToken() async {
    if (!_firebaseReady) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await saveToken(token);
      }
    } catch (e) {
      debugPrint('FcmTokenService.registerCurrentToken failed: $e');
    }
  }

  /// Adds [token] to the signed-in user's token list.
  Future<void> saveToken(String token) async {
    final uid = _uid;
    if (!_firebaseReady || uid == null || token.isEmpty) return;
    try {
      await _db.collection('users').doc(uid).set({
        'fcm_tokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FcmTokenService.saveToken failed: $e');
    }
  }

  /// Removes this device's token on sign-out so the user stops receiving
  /// pushes for this account on this device.
  Future<void> removeCurrentToken() async {
    final uid = _uid;
    if (!_firebaseReady || uid == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _db.collection('users').doc(uid).set({
        'fcm_tokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FcmTokenService.removeCurrentToken failed: $e');
    }
  }
}
