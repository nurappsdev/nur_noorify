class DuaItem {
  const DuaItem({
    required this.id,
    required this.uid,
    required this.mainCategory,
    required this.category,
    required this.titleEn,
    required this.titleBn,
    required this.arabic,
    required this.english,
    required this.bangla,
    required this.reference,
    required this.audio,
    required this.contentVersion,
    required this.updatedAt,
    required this.isActive,
    required this.sortOrder,
  });

  final int id;
  final String uid;
  final String mainCategory;
  final String category;
  final String titleEn;
  final String titleBn;
  final String arabic;
  final String english;
  final String bangla;
  final String reference;
  final String? audio;
  final int contentVersion;
  final String updatedAt;
  final bool isActive;
  final int sortOrder;

  factory DuaItem.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt() ?? 0;
    return DuaItem(
      id: id,
      uid: (json['uid'] ?? 'dua_${id.toString().padLeft(4, '0')}').toString(),
      mainCategory: _resolveMainCategory(
        (json['main_category'] ?? '').toString(),
        (json['category'] ?? 'general').toString(),
      ),
      category: (json['category'] ?? 'general').toString(),
      titleEn: (json['title_en'] ?? '').toString(),
      titleBn: (json['title_bn'] ?? '').toString(),
      arabic: (json['arabic'] ?? '').toString(),
      english: (json['english'] ?? '').toString(),
      bangla: (json['bangla'] ?? '').toString(),
      reference: (json['reference'] ?? '').toString(),
      audio: json['audio']?.toString(),
      contentVersion: (json['content_version'] as num?)?.toInt() ?? 1,
      updatedAt: (json['updated_at'] ?? '').toString(),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'main_category': mainCategory,
      'category': category,
      'title_en': titleEn,
      'title_bn': titleBn,
      'arabic': arabic,
      'english': english,
      'bangla': bangla,
      'reference': reference,
      'audio': audio,
      'content_version': contentVersion,
      'updated_at': updatedAt,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  static String _resolveMainCategory(String provided, String category) {
    final trimmed = provided.trim().toLowerCase();
    if (trimmed.isNotEmpty) return trimmed;
    if (category.startsWith('after_')) return 'namaj';
    return 'general';
  }
}
