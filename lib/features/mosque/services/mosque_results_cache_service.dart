import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:first_project/features/mosque/models/mosque_item.dart';

class MosqueCachedResults {
  const MosqueCachedResults({
    required this.queryLatitude,
    required this.queryLongitude,
    required this.radiusMeters,
    required this.updatedAt,
    required this.items,
  });

  final double queryLatitude;
  final double queryLongitude;
  final int radiusMeters;
  final DateTime updatedAt;
  final List<MosqueItem> items;
}

class MosqueResultsCacheService {
  MosqueResultsCacheService({BaseCacheManager? cache})
    : _cache = cache ?? DefaultCacheManager();

  static const _cacheKey = 'mosque_results_cache_v1';
  final BaseCacheManager _cache;

  Future<void> save({
    required double queryLatitude,
    required double queryLongitude,
    required int radiusMeters,
    required List<MosqueItem> items,
  }) async {
    final payload = <String, dynamic>{
      'query_latitude': queryLatitude,
      'query_longitude': queryLongitude,
      'radius_meters': radiusMeters,
      'updated_at': DateTime.now().toIso8601String(),
      'items': items
          .map(
            (e) => {
              'id': e.id,
              'name': e.name,
              'latitude': e.latitude,
              'longitude': e.longitude,
              'distance_km': e.distanceKm,
              'address': e.address,
            },
          )
          .toList(growable: false),
    };

    final raw = jsonEncode(payload);
    await _cache.putFile(
      _cacheKey,
      Uint8List.fromList(utf8.encode(raw)),
      key: _cacheKey,
      fileExtension: 'json',
    );
  }

  Future<MosqueCachedResults?> load() async {
    final fileInfo = await _cache.getFileFromCache(_cacheKey);
    if (fileInfo == null || !await fileInfo.file.exists()) return null;

    try {
      final decoded = jsonDecode(await fileInfo.file.readAsString());
      if (decoded is! Map) return null;

      final queryLatitude = (decoded['query_latitude'] as num?)?.toDouble();
      final queryLongitude = (decoded['query_longitude'] as num?)?.toDouble();
      final radiusMeters = (decoded['radius_meters'] as num?)?.toInt();
      final updatedAtRaw = (decoded['updated_at'] ?? '').toString();
      final updatedAt = DateTime.tryParse(updatedAtRaw);
      final list = decoded['items'];

      if (queryLatitude == null ||
          queryLongitude == null ||
          radiusMeters == null ||
          updatedAt == null ||
          list is! List) {
        return null;
      }

      final items = <MosqueItem>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final id = (map['id'] as num?)?.toInt() ?? (items.length + 1);
        final name = (map['name'] ?? '').toString();
        final lat = (map['latitude'] as num?)?.toDouble();
        final lng = (map['longitude'] as num?)?.toDouble();
        final distanceKm = (map['distance_km'] as num?)?.toDouble();
        final address = (map['address'] ?? '').toString();
        if (lat == null || lng == null || distanceKm == null) continue;

        items.add(
          MosqueItem(
            id: id,
            name: name.isEmpty ? 'Mosque' : name,
            latitude: lat,
            longitude: lng,
            distanceKm: distanceKm,
            address: address.isEmpty ? 'Nearby area' : address,
          ),
        );
      }

      return MosqueCachedResults(
        queryLatitude: queryLatitude,
        queryLongitude: queryLongitude,
        radiusMeters: radiusMeters,
        updatedAt: updatedAt,
        items: items,
      );
    } catch (_) {
      return null;
    }
  }
}
