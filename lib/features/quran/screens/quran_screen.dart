// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// import 'package:first_project/core/theme/brand_colors.dart';
// import 'package:first_project/features/quran/models/quran_models.dart';
// import 'package:first_project/features/quran/screens/quran_bookmarks_screen.dart';
// import 'package:first_project/features/quran/screens/surah_detail_screen.dart';
// import 'package:first_project/features/quran/services/quran_api_service.dart';
// import 'package:first_project/features/quran/services/quran_bookmarks_service.dart';
// import 'package:first_project/features/quran/services/quran_content_cache_service.dart';
// import 'package:first_project/features/quran/services/quran_last_read_service.dart';
// import 'package:first_project/features/quran/utils/quran_utils.dart';
// import 'package:first_project/features/quran/widgets/quran_header.dart';
// import 'package:first_project/features/quran/widgets/quran_list_widgets.dart';
// import 'package:first_project/shared/widgets/noorify_glass.dart';
//
// class QuranScreen extends StatefulWidget {
//   const QuranScreen({super.key});
//   @override
//   State<QuranScreen> createState() => _QuranScreenState();
// }
//
// class _QuranScreenState extends State<QuranScreen> {
//   final QuranApiService _api = QuranApiService();
//   final QuranContentCacheService _contentCache = QuranContentCacheService();
//   final QuranBookmarksService _bookmarksService = QuranBookmarksService();
//   final QuranLastReadService _lastReadService = QuranLastReadService();
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _searchFocusNode = FocusNode();
//   final ScrollController _surahListController = ScrollController();
//   final Set<int> _downloadedSurahNos = {};
//   bool _isLoading = true, _isTopCollapsed = false, _showOnlyDownloaded = false, _isBulkCaching = false;
//   String? _error;
//   String _searchQuery = '', _filter = 'all';
//   int? _lastReadSurahNo, _lastReadAyahNo;
//   List<QuranAyahBookmark> _bookmarks = [];
//   List<QuranChapter> _chapters = [];
//   int _bulkCacheCompleted = 0, _bulkCacheTotal = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(() => setState(() => _searchQuery = _searchController.text.trim().toLowerCase()));
//     _surahListController.addListener(() {
//       if (_searchFocusNode.hasFocus) return;
//       final coll = _surahListController.hasClients && _surahListController.offset > 28;
//       if (coll != _isTopCollapsed) setState(() => _isTopCollapsed = coll);
//     });
//     _loadAll();
//   }
//
//   Future<void> _loadAll() async {
//     final saved = await _lastReadService.readLastRead();
//     final items = await _bookmarksService.readAll();
//     setState(() { _lastReadSurahNo = saved?.surahNo; _lastReadAyahNo = saved?.ayahNo; _bookmarks = items; });
//     _loadChapters();
//   }
//
//   Future<void> _loadChapters() async {
//     setState(() { _isLoading = true; _error = null; });
//     try {
//       final chapters = await _api.fetchChapters();
//       setState(() { _chapters = chapters; _isLoading = false; });
//       final downloaded = await _refreshDownloadedFlags();
//       if (!_api.lastReadFromCache) unawaited(_autoCacheAll(chapters, downloaded));
//     } catch (_) { setState(() { _error = QuranUtils.t('Could not load Quran list.', 'কুরআনের তালিকা লোড করা যায়নি।'); _isLoading = false; }); }
//   }
//
//   Future<Set<int>> _refreshDownloadedFlags() async {
//     final downloaded = <int>{};
//     for (final c in _chapters) { if (await _contentCache.readSurahDetail(c.surahNo, lang: 'bn') != null) downloaded.add(c.surahNo); }
//     setState(() { _downloadedSurahNos.clear(); _downloadedSurahNos.addAll(downloaded); });
//     return downloaded;
//   }
//
//   Future<void> _autoCacheAll(List<QuranChapter> chapters, Set<int> downloaded) async {
//     final missing = chapters.where((c) => !downloaded.contains(c.surahNo)).toList();
//     if (missing.isEmpty) return;
//     setState(() { _isBulkCaching = true; _bulkCacheTotal = chapters.length; _bulkCacheCompleted = downloaded.length; });
//     for (final c in missing) {
//       try { await _api.fetchSurahDetail(c.surahNo, lang: 'bn'); downloaded.add(c.surahNo); } catch (_) {}
//       setState(() { _bulkCacheCompleted = downloaded.length; _downloadedSurahNos.clear(); _downloadedSurahNos.addAll(downloaded); });
//     }
//     setState(() => _isBulkCaching = false);
//   }
//
//   ({int ayahNo, double progress}) _progress(QuranChapter c) {
//     if (c.totalAyah <= 0) return (ayahNo: 0, progress: 0);
//     var best = (_lastReadSurahNo == c.surahNo) ? (_lastReadAyahNo ?? 0) : 0;
//     if (best <= 0) for (final b in _bookmarks) { if (b.surahNo == c.surahNo && b.ayahNo > best) best = b.ayahNo; }
//     final safe = best.clamp(0, c.totalAyah);
//     return (ayahNo: safe, progress: safe / c.totalAyah);
//   }
//
//   Future<void> _showDetail(QuranChapter c, {int? initialAyahNo}) async {
//     if (_lastReadSurahNo != c.surahNo) {
//       setState(() { _lastReadSurahNo = c.surahNo; _lastReadAyahNo = 1; });
//       unawaited(_lastReadService.saveLastRead(surahNo: c.surahNo, ayahNo: 1));
//     }
//     final downloaded = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => SurahDetailScreen(chapter: c, initialAyahNo: initialAyahNo)));
//     await _loadAll();
//     if (downloaded == true) setState(() => _downloadedSurahNos.add(c.surahNo));
//   }
//
//   Future<void> _openBookmarks() async {
//     if (_bookmarks.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(QuranUtils.t('No saved ayah bookmarks yet', 'এখনও কোনো আয়াত বুকমার্ক সেভ করা হয়নি')))); return; }
//     final sel = await Navigator.of(context).push<QuranAyahBookmark>(MaterialPageRoute(builder: (_) => QuranBookmarksScreen(bookmarks: _bookmarks)));
//     if (sel != null) _showDetail(_chapters.firstWhere((c) => c.surahNo == sel.surahNo), initialAyahNo: sel.ayahNo);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final glass = NoorifyGlassTheme(context);
//     final filtered = _chapters.where((c) {
//       if (_showOnlyDownloaded && !_downloadedSurahNos.contains(c.surahNo)) return false;
//       if (_filter == 'meccan' && !c.isMeccan) return false;
//       if (_filter == 'medinan' && !c.isMedinan) return false;
//       return _searchQuery.isEmpty || c.surahNo.toString() == _searchQuery || c.surahName.toLowerCase().contains(_searchQuery) || c.surahNameArabic.contains(_searchQuery);
//     }).toList();
//
//     return Scaffold(
//       backgroundColor: glass.bgBottom,
//       body: NoorifyGlassBackground(
//         child: SafeArea(
//           child: Column(children: [
//             AnimatedCrossFade(
//               duration: const Duration(milliseconds: 240),
//               crossFadeState: _isTopCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
//               firstChild: Column(children: [
//                 QuranHeader(lastReadChapter: _chapters.firstWhere((c) => c.surahNo == (_lastReadSurahNo ?? 2), orElse: () => _chapters.first), lastReadProgress: _progress(_chapters.firstWhere((c) => c.surahNo == (_lastReadSurahNo ?? 2), orElse: () => _chapters.first)), onContinueTap: () => _showDetail(_chapters.firstWhere((c) => c.surahNo == (_lastReadSurahNo ?? 2), orElse: () => _chapters.first))),
//                 Padding(
//                   padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
//                   child: Column(children: [
//                     Container(padding: EdgeInsets.all(5.r), decoration: BoxDecoration(color: glass.isDark ? const Color(0x3816232F) : Colors.white, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: glass.isDark ? const Color(0x6AA9C7DB) : const Color(0x88D1E1EC))), child: Row(children: [
//                       Expanded(child: FilterChipButton(label: QuranUtils.t('All', 'সব'), selected: _filter == 'all', isSegment: true, onTap: () => setState(() => _filter = 'all'))), SizedBox(width: 6.w),
//                       Expanded(child: FilterChipButton(label: QuranUtils.t('Makkah', 'মক্কী'), selected: _filter == 'meccan', isSegment: true, onTap: () => setState(() => _filter = 'meccan'))), SizedBox(width: 6.w),
//                       Expanded(child: FilterChipButton(label: QuranUtils.t('Madinah', 'মাদানী'), selected: _filter == 'medinan', isSegment: true, onTap: () => setState(() => _filter = 'medinan'))), SizedBox(width: 6.w),
//                       Expanded(child: FilterChipButton(label: QuranUtils.t('Saved', 'সেভড'), selected: _showOnlyDownloaded, isSegment: true, onTap: () => setState(() => _showOnlyDownloaded = !_showOnlyDownloaded))),
//                     ])),
//                     SizedBox(height: 10.h),
//                     TextField(controller: _searchController, focusNode: _searchFocusNode, style: TextStyle(color: glass.textPrimary, fontWeight: FontWeight.w600), decoration: InputDecoration(hintText: QuranUtils.t('Search', 'খুঁজুন'), prefixIcon: Icon(Icons.search_rounded, color: glass.textSecondary), filled: true, fillColor: glass.isDark ? const Color(0xC4142331) : const Color(0xFFF9FCFF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: glass.isDark ? const Color(0x66A9C7DB) : const Color(0xFFBDD5E4)))),
//                     if (_isBulkCaching) ...[SizedBox(height: 10.h), LinearProgressIndicator(value: _bulkCacheCompleted / _bulkCacheTotal, backgroundColor: Colors.white, valueColor: const AlwaysStoppedAnimation(BrandColors.primary))],
//                   ]),
//                 ),
//               ]),
//               secondChild: Padding(padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 6.h), child: NoorifyGlassCard(radius: BorderRadius.circular(14.r), child: Row(children: [
//                 Text(QuranUtils.t('Quran', 'কুরআন'), style: TextStyle(color: glass.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w700)), const Spacer(),
//                 IconButton(onPressed: () { setState(() => _isTopCollapsed = false); Future.delayed(const Duration(milliseconds: 220), () => _searchFocusNode.requestFocus()); }, icon: Icon(Icons.search_rounded, color: glass.accent)),
//                 IconButton(onPressed: _openBookmarks, icon: Icon(_bookmarks.isEmpty ? Icons.bookmark_border_rounded : Icons.bookmark_rounded, color: glass.accent)),
//                 IconButton(onPressed: () { if (_surahListController.hasClients) _surahListController.animateTo(0, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic); setState(() => _isTopCollapsed = false); }, icon: Icon(Icons.expand_more_rounded, color: glass.accent)),
//               ]))),
//             ),
//             Expanded(child: _isLoading ? Center(child: CircularProgressIndicator(color: glass.accent)) : _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, style: TextStyle(color: glass.textSecondary)), SizedBox(height: 8.h), FilledButton(onPressed: _loadChapters, style: FilledButton.styleFrom(backgroundColor: glass.accent), child: Text(QuranUtils.t('Retry', 'আবার চেষ্টা করুন')))])) : ListView.builder(controller: _surahListController, padding: EdgeInsets.symmetric(horizontal: 16.w), itemCount: filtered.length, itemBuilder: (context, index) => Padding(padding: EdgeInsets.only(bottom: 10.h), child: QuranSurahTile(chapter: filtered[index], hasBookmark: _bookmarks.any((b) => b.surahNo == filtered[index].surahNo), onTap: () => _showDetail(filtered[index]), onBookmarkTap: _openBookmarks)))),
//           ]),
//         ),
//       ),
//     );
//   }
// }
