import 'package:flutter/material.dart';

class MainCategoryMeta {
  const MainCategoryMeta({
    required this.key,
    required this.titleEn,
    required this.titleBn,
    required this.subtitleEn,
    required this.subtitleBn,
    required this.icon,
  });

  final String key;
  final String titleEn;
  final String titleBn;
  final String subtitleEn;
  final String subtitleBn;
  final IconData icon;

  static MainCategoryMeta fallback(String key) {
    final human = key.replaceAll('_', ' ').trim();
    final titled = human.isEmpty ? 'General' : '${human[0].toUpperCase()}${human.substring(1)}';
    return MainCategoryMeta(
      key: key,
      titleEn: titled,
      titleBn: 'সাধারণ',
      subtitleEn: 'Custom category',
      subtitleBn: 'কাস্টম ক্যাটাগরি',
      icon: Icons.grid_view_rounded,
    );
  }
}

class SubCategoryMeta {
  const SubCategoryMeta({
    required this.key,
    required this.mainKey,
    required this.titleEn,
    required this.titleBn,
    required this.icon,
  });

  final String key;
  final String mainKey;
  final String titleEn;
  final String titleBn;
  final IconData icon;

  static SubCategoryMeta fallback({required String key, required String mainKey}) {
    final human = key.replaceAll('_', ' ').trim();
    final titled = human.isEmpty ? 'General Item' : '${human[0].toUpperCase()}${human.substring(1)}';
    return SubCategoryMeta(
      key: key,
      mainKey: mainKey,
      titleEn: titled,
      titleBn: 'ক্যাটাগরি',
      icon: Icons.bookmark_outline_rounded,
    );
  }
}

class MainCategoryTileData {
  const MainCategoryTileData({
    required this.meta,
    required this.duaCount,
    required this.subCategoryCount,
  });

  final MainCategoryMeta meta;
  final int duaCount;
  final int subCategoryCount;
}

class SubCategoryTileData {
  const SubCategoryTileData({required this.meta, required this.duaCount});

  final SubCategoryMeta meta;
  final int duaCount;
}
