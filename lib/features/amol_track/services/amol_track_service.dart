import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Persists which deeds the user has marked done, keyed by calendar date.
///
/// Storage is a single JSON document of the shape
/// `{ "2026-06-04": ["fajr", "zuhr"], ... }`, written through the same
/// [DefaultCacheManager] the rest of the app uses for local preferences, so no
/// extra storage dependency is introduced. All state is local to the device.
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

  /// Normalises a [DateTime] to a stable `yyyy-MM-dd` storage key.
  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> load() async {
    if (_loaded) return;
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
    _loaded = true;
  }

  /// The set of completed item ids for [date] (empty if none recorded).
  Set<String> completedFor(DateTime date) =>
      Set<String>.from(_byDate[dateKey(date)] ?? const <String>{});

  /// Count of completed deeds for [date].
  int completedCountFor(DateTime date) => _byDate[dateKey(date)]?.length ?? 0;

  /// Flips the done state of [itemId] on [date] and persists the change.
  Future<bool> toggle(DateTime date, String itemId) async {
    final key = dateKey(date);
    final set = _byDate.putIfAbsent(key, () => <String>{});
    final nowDone = !set.remove(itemId);
    if (nowDone) set.add(itemId);
    if (set.isEmpty) _byDate.remove(key);
    revision.value++;
    await _persist();
    return nowDone;
  }

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
}
