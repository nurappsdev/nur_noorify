import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:first_project/features/quran/models/quran_models.dart';
import 'package:first_project/features/quran/services/quran_api_service.dart';
import 'package:first_project/features/quran/services/quran_bookmarks_service.dart';
import 'package:first_project/features/quran/services/quran_content_cache_service.dart';
import 'package:first_project/features/quran/services/quran_last_read_service.dart';

class QuranBulkCacheResult {
  const QuranBulkCacheResult({
    required this.success,
    required this.failed,
    required this.total,
  });

  final int success;
  final int failed;
  final int total;
}

class QuranLoadChaptersResult {
  const QuranLoadChaptersResult({
    required this.success,
    required this.fromCache,
  });

  final bool success;
  final bool fromCache;
}

class QuranScreenProvider extends ChangeNotifier {
  final QuranApiService _api = QuranApiService();
  final QuranContentCacheService _contentCache = QuranContentCacheService();
  final QuranBookmarksService _bookmarksService = QuranBookmarksService();
  final QuranLastReadService _lastReadService = QuranLastReadService();

  final Set<int> _downloadedSurahNos = <int>{};
  List<QuranChapter> _chapters = <QuranChapter>[];
  List<QuranAyahBookmark> _bookmarks = const <QuranAyahBookmark>[];

  bool _isLoading = true;
  bool _disposed = false;
  String? _error;
  String _searchQuery = '';
  String _filter = 'all';
  bool _showOnlyDownloaded = false;
  int? _lastReadSurahNo;
  int? _lastReadAyahNo;
  bool _isTopCollapsed = false;
  bool _isBulkCachingText = false;
  int _bulkCacheCompleted = 0;
  int _bulkCacheTotal = 0;

  List<QuranChapter> get chapters => _chapters;
  List<QuranAyahBookmark> get bookmarks => _bookmarks;
  Set<int> get downloadedSurahNos => _downloadedSurahNos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get filter => _filter;
  bool get showOnlyDownloaded => _showOnlyDownloaded;
  int? get lastReadSurahNo => _lastReadSurahNo;
  int? get lastReadAyahNo => _lastReadAyahNo;
  bool get isTopCollapsed => _isTopCollapsed;
  bool get isBulkCachingText => _isBulkCachingText;
  int get bulkCacheCompleted => _bulkCacheCompleted;
  int get bulkCacheTotal => _bulkCacheTotal;

  bool get showBulkCacheProgress =>
      _isBulkCachingText ||
      (_bulkCacheTotal > 0 && _bulkCacheCompleted < _bulkCacheTotal);

  double get bulkCacheProgressValue {
    if (_bulkCacheTotal <= 0) return 0;
    return (_bulkCacheCompleted / _bulkCacheTotal).clamp(0.0, 1.0).toDouble();
  }

  List<QuranChapter> get filteredChapters {
    return _chapters
        .where((chapter) {
          if (_showOnlyDownloaded &&
              !_downloadedSurahNos.contains(chapter.surahNo)) {
            return false;
          }
          if (_filter == 'meccan' && !chapter.isMeccan) return false;
          if (_filter == 'medinan' && !chapter.isMedinan) return false;
          if (_searchQuery.isEmpty) return true;
          return chapter.surahNo.toString() == _searchQuery ||
              chapter.surahName.toLowerCase().contains(_searchQuery) ||
              chapter.surahNameArabic.contains(_searchQuery) ||
              chapter.surahNameTranslation.toLowerCase().contains(_searchQuery);
        })
        .toList(growable: false);
  }

  QuranAyahBookmark? firstBookmarkForSurah(int surahNo) {
    for (final bookmark in _bookmarks) {
      if (bookmark.surahNo == surahNo) return bookmark;
    }
    return null;
  }

  ({int ayahNo, double progress}) lastReadProgressForSurah(
    QuranChapter chapter,
  ) {
    if (chapter.totalAyah <= 0) return (ayahNo: 0, progress: 0);
    var bestAyah = 0;
    if (_lastReadSurahNo == chapter.surahNo && (_lastReadAyahNo ?? 0) > 0) {
      bestAyah = _lastReadAyahNo!;
    }
    if (bestAyah <= 0) {
      for (final bookmark in _bookmarks) {
        if (bookmark.surahNo == chapter.surahNo && bookmark.ayahNo > bestAyah) {
          bestAyah = bookmark.ayahNo;
        }
      }
    }
    final safeAyah = bestAyah.clamp(0, chapter.totalAyah);
    return (ayahNo: safeAyah, progress: safeAyah / chapter.totalAyah);
  }

  void setSearchQuery(String value) {
    final next = value.trim().toLowerCase();
    if (next == _searchQuery) return;
    _searchQuery = next;
    _safeNotify();
  }

  void setFilter(String value) {
    if (value == _filter) return;
    _filter = value;
    _safeNotify();
  }

  void toggleShowOnlyDownloaded() {
    _showOnlyDownloaded = !_showOnlyDownloaded;
    _safeNotify();
  }

  void setTopCollapsed(bool value) {
    if (_isTopCollapsed == value) return;
    _isTopCollapsed = value;
    _safeNotify();
  }

  void markSurahDownloaded(int surahNo) {
    if (_downloadedSurahNos.add(surahNo)) _safeNotify();
  }

  void markLastRead({required int surahNo, required int ayahNo}) {
    if (_lastReadSurahNo == surahNo && _lastReadAyahNo == ayahNo) return;
    _lastReadSurahNo = surahNo;
    _lastReadAyahNo = ayahNo;
    _safeNotify();
    unawaited(_lastReadService.saveLastRead(surahNo: surahNo, ayahNo: ayahNo));
  }

  Future<void> loadBookmarks() async {
    final items = await _bookmarksService.readAll();
    if (_disposed) return;
    _bookmarks = items;
    _safeNotify();
  }

  Future<void> restoreLastRead() async {
    final saved = await _lastReadService.readLastRead();
    if (_disposed || saved == null) return;
    _lastReadSurahNo = saved.surahNo;
    _lastReadAyahNo = saved.ayahNo;
    _safeNotify();
  }

  Future<QuranLoadChaptersResult> loadChapters({
    required String errorMessage,
  }) async {
    _isLoading = true;
    _error = null;
    _safeNotify();
    try {
      final chapters = await _api.fetchChapters();
      final fromCache = _api.lastReadFromCache;
      _chapters = chapters;
      _isLoading = false;
      _safeNotify();
      await _refreshDownloadedFlags();
      return QuranLoadChaptersResult(success: true, fromCache: fromCache);
    } catch (_) {
      _error = errorMessage;
      _isLoading = false;
      _safeNotify();
      return const QuranLoadChaptersResult(success: false, fromCache: false);
    }
  }

  Future<Set<int>> _refreshDownloadedFlags() async {
    final chapters = List<QuranChapter>.from(_chapters);
    final downloaded = <int>{};
    for (final chapter in chapters) {
      final detail = await _contentCache.readSurahDetail(
        chapter.surahNo,
        lang: 'bn',
      );
      if (detail != null) downloaded.add(chapter.surahNo);
    }
    if (_disposed) return downloaded;
    _downloadedSurahNos
      ..clear()
      ..addAll(downloaded);
    _safeNotify();
    return downloaded;
  }

  Future<QuranBulkCacheResult?> autoCacheAllTextIfNeeded() async {
    if (_isBulkCachingText) return null;
    final chapters = List<QuranChapter>.from(_chapters);
    final downloaded = Set<int>.from(_downloadedSurahNos);
    final missing = chapters
        .where((chapter) => !downloaded.contains(chapter.surahNo))
        .toList(growable: false);
    if (missing.isEmpty) return null;

    _isBulkCachingText = true;
    _bulkCacheTotal = chapters.length;
    _bulkCacheCompleted = downloaded.length;
    _safeNotify();

    var failed = 0;
    for (final chapter in missing) {
      try {
        await _api.fetchSurahDetail(chapter.surahNo, lang: 'bn');
        downloaded.add(chapter.surahNo);
      } catch (_) {
        failed += 1;
      }
      if (_disposed) {
        return QuranBulkCacheResult(
          success: downloaded.length,
          failed: failed,
          total: chapters.length,
        );
      }
      _bulkCacheCompleted = downloaded.length;
      _downloadedSurahNos
        ..clear()
        ..addAll(downloaded);
      _safeNotify();
    }

    _isBulkCachingText = false;
    _safeNotify();
    return QuranBulkCacheResult(
      success: downloaded.length,
      failed: failed,
      total: chapters.length,
    );
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
