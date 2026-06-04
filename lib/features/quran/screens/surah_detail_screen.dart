import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/core/theme/brand_colors.dart';
import 'package:first_project/features/quran/models/quran_models.dart';
import 'package:first_project/features/quran/screens/quran_bookmarks_screen.dart';
import 'package:first_project/features/quran/services/quran_api_service.dart';
import 'package:first_project/features/quran/services/quran_ayah_audio_service.dart';
import 'package:first_project/features/quran/services/quran_offline_download_service.dart';
import 'package:first_project/features/quran/services/quran_bookmarks_service.dart';
import 'package:first_project/features/quran/services/quran_last_read_service.dart';
import 'package:first_project/features/quran/services/quran_tafsir_service.dart';
import 'package:first_project/features/quran/services/quran_timing_service.dart';

class SurahDetailScreen extends StatefulWidget {
  const SurahDetailScreen({
    super.key,
    required this.chapter,
    this.autoStartAudio = false,
    this.initialAyahNo,
  });

  final QuranChapter chapter;
  final bool autoStartAudio;
  final int? initialAyahNo;

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranApiService _api = QuranApiService();
  final QuranAyahAudioService _ayahAudio = QuranAyahAudioService();
  final QuranOfflineDownloadService _offline = QuranOfflineDownloadService();
  final QuranBookmarksService _bookmarks = QuranBookmarksService();
  final QuranLastReadService _lastRead = QuranLastReadService();
  final QuranTafsirService _tafsir = QuranTafsirService();
  final QuranTimingService _timing = QuranTimingService();
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  QuranSurahDetail? _detail;
  String? _error;
  bool _isLoading = true;
  bool _isPreparingAudio = false;
  bool _isDownloadingAudio = false;
  bool _didDownloadAudio = false;
  bool _usingCachedContent = false;
  bool _showBottomPlayer = false;

  int? _selectedReciterId;
  String? _preparedAudioUrl;
  final Set<String> _cachedAudioUrls = {};
  int? _timingRecitationId;
  String? _timingAudioUrl;
  List<QuranTimingSegment> _timingSegments = const [];

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final Map<int, GlobalKey> _ayahItemKeys = {};
  int _lastAutoScrolledAyahIndex = -1;
  bool _singleAyahMode = false;
  int? _singleAyahIndex;
  int? _singleAyahStartMs;
  int? _singleAyahStopMs;
  bool _isStoppingSingleAyah = false;
  int _hifzRepeatsLeft = 0;
  bool _didJumpToInitialAyah = false;
  Map<int, QuranAyahBookmark> _bookmarksByAyahNo = const {};
  int _lastSavedAyahNo = 0;

  bool get _hifzModeEnabled => hifzModeEnabledNotifier.value;
  bool get _hifzHideBanglaMeaning => hifzHideBanglaMeaningNotifier.value;
  int get _hifzRepeatCount => hifzRepeatCountNotifier.value;
  bool get _showTranslation => showTranslationNotifier.value;
  String get _translationLanguage => translationLanguageNotifier.value;
  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;
  bool get _isDarkTheme => Theme.of(context).brightness == Brightness.dark;

  String _t(String en, String bn) {
    if (!_isBangla) return en;
    final repaired = _repairMojibake(bn);
    if (_looksMojibake(repaired)) return en;
    return repaired;
  }

  Color get _bgTop =>
      _isDarkTheme ? const Color(0xFF081522) : const Color(0xFFF7FBFF);
  Color get _bgMid =>
      _isDarkTheme ? const Color(0xFF0C1B2B) : const Color(0xFFEAF4FB);
  Color get _bgBottom =>
      _isDarkTheme ? const Color(0xFF091421) : const Color(0xFFF2F8FD);

  Color get _glassStart =>
      _isDarkTheme ? const Color(0xCC142231) : const Color(0xF2FFFFFF);
  Color get _glassEnd =>
      _isDarkTheme ? const Color(0xB0111C29) : const Color(0xDBF2F8FD);
  Color get _glassBorder =>
      _isDarkTheme ? const Color(0x449ECFF2) : const Color(0xCCD1E1EC);
  Color get _glassShadow =>
      _isDarkTheme ? const Color(0x66000000) : const Color(0x260E3853);

  Color get _screenTextPrimary =>
      _isDarkTheme ? const Color(0xFFEAF5FF) : const Color(0xFF143349);
  Color get _screenTextSecondary =>
      _isDarkTheme ? const Color(0xFF9FBBD0) : const Color(0xFF5F7E94);
  Color get _screenTextMuted =>
      _isDarkTheme ? const Color(0xFF7E9DB3) : const Color(0xFF4D6B82);
  Color get _accent =>
      _isDarkTheme ? const Color(0xFF2EB8E6) : const Color(0xFF1EA8B8);

  Widget _buildGlassPanel({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) {
    final resolvedPadding = padding ?? EdgeInsets.all(14.r);
    final resolvedRadius =
        borderRadius ?? BorderRadius.all(Radius.circular(18.r));
    return ClipRRect(
      borderRadius: resolvedRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: resolvedPadding,
          decoration: BoxDecoration(
            borderRadius: resolvedRadius,
            gradient: LinearGradient(
              colors: [_glassStart, _glassEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _glassBorder),
            boxShadow: [
              BoxShadow(
                color: _glassShadow,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  void _resetSingleAyahPlaybackState() {
    _singleAyahMode = false;
    _singleAyahIndex = null;
    _singleAyahStartMs = null;
    _singleAyahStopMs = null;
    _hifzRepeatsLeft = 0;
  }

  int _targetRepeatCountForMode() {
    return _hifzModeEnabled ? _hifzRepeatCount : 1;
  }

  @override
  void initState() {
    super.initState();
    appLanguageNotifier.addListener(_onReadingPreferenceChanged);
    showTranslationNotifier.addListener(_onReadingPreferenceChanged);
    translationLanguageNotifier.addListener(_onReadingPreferenceChanged);
    _bindAudioStreams();
    _loadSurahDetail();
    _loadBookmarksForCurrentSurah();
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onReadingPreferenceChanged);
    showTranslationNotifier.removeListener(_onReadingPreferenceChanged);
    translationLanguageNotifier.removeListener(_onReadingPreferenceChanged);
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _onReadingPreferenceChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool _looksMojibake(String value) {
    for (final unit in value.codeUnits) {
      if (unit == 0x00C3 ||
          unit == 0x00C2 ||
          unit == 0x00E0 ||
          unit == 0x00D8 ||
          unit == 0x00D9 ||
          unit == 0x00D0 ||
          unit == 0x00E2) {
        return true;
      }
    }
    return false;
  }

  String _repairMojibake(String value) {
    var output = value;
    for (var i = 0; i < 2; i++) {
      if (!_looksMojibake(output)) break;
      try {
        output = utf8.decode(latin1.encode(output));
      } catch (_) {
        break;
      }
    }
    return output;
  }

  void _bindAudioStreams() {
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (_singleAyahMode &&
          state.processingState == ProcessingState.completed &&
          !state.playing) {
        unawaited(_handleCompletedSingleAyahTrack());
      }
      setState(() {
        _isPlaying = state.playing;
      });
    });

    _positionSub = _player.positionStream.listen((position) {
      if (!mounted) return;
      if (_singleAyahMode &&
          _singleAyahStopMs != null &&
          !_isStoppingSingleAyah &&
          position.inMilliseconds >= _singleAyahStopMs!) {
        unawaited(_stopAtSingleAyahBoundary());
      }
      setState(() => _position = position);
    });

    _durationSub = _player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration ?? Duration.zero);
    });
  }

  Future<void> _handleCompletedSingleAyahTrack() async {
    if (!_singleAyahMode) return;
    if (_hifzModeEnabled && _hifzRepeatsLeft > 1) {
      final nextRepeatsLeft = _hifzRepeatsLeft - 1;
      await _player.seek(Duration.zero);
      if (!mounted) return;
      setState(() {
        _hifzRepeatsLeft = nextRepeatsLeft;
        _lastAutoScrolledAyahIndex = -1;
      });
      await _player.play();
      return;
    }

    if (!mounted) return;
    setState(_resetSingleAyahPlaybackState);
  }

  Future<void> _stopAtSingleAyahBoundary() async {
    if (_isStoppingSingleAyah) return;
    _isStoppingSingleAyah = true;
    try {
      if (_hifzModeEnabled &&
          _singleAyahMode &&
          _singleAyahStartMs != null &&
          _hifzRepeatsLeft > 1) {
        final nextRepeatsLeft = _hifzRepeatsLeft - 1;
        await _player.seek(Duration(milliseconds: _singleAyahStartMs!));
        if (!mounted) return;
        setState(() {
          _hifzRepeatsLeft = nextRepeatsLeft;
          _lastAutoScrolledAyahIndex = -1;
        });
        await _player.play();
        return;
      }

      await _player.pause();
      if (!mounted) return;
      setState(_resetSingleAyahPlaybackState);
    } finally {
      _isStoppingSingleAyah = false;
    }
  }

  Future<void> _loadSurahDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await _api.fetchSurahDetail(
        widget.chapter.surahNo,
        lang: 'bn',
      );
      final fromCache = _api.lastReadFromCache;
      final cachedUrls = <String>{};
      for (final reciter in detail.audioByReciter) {
        final isCached = await _offline.hasAudio(reciter.url);
        if (isCached) cachedUrls.add(reciter.url);
      }

      if (!mounted) return;
      setState(() {
        _detail = detail;
        _selectedReciterId = detail.audioByReciter.isNotEmpty
            ? detail.audioByReciter.first.id
            : null;
        _cachedAudioUrls
          ..clear()
          ..addAll(cachedUrls);
        _usingCachedContent = fromCache;
        _timingRecitationId = null;
        _timingAudioUrl = null;
        _timingSegments = const [];
        _preparedAudioUrl = null;
        _showBottomPlayer = widget.autoStartAudio;
        _isLoading = false;
      });
      _trackLastReadAyah(widget.initialAyahNo ?? 1);

      await _resolveTimingForSelectedReciter();

      if (widget.autoStartAudio) {
        await _togglePlayPause();
      }

      if (!mounted) return;
      if (fromCache) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Showing offline saved Surah content.',
                'অফলাইনে সেভ করা সূরা কনটেন্ট দেখানো হচ্ছে।',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _t(
          'Could not load Surah details. Please connect to internet once and try again.',
          'সূরার বিস্তারিত লোড করা যায়নি। একবার ইন্টারনেটে যুক্ত হয়ে আবার চেষ্টা করুন।',
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _resolveTimingForSelectedReciter() async {
    final reciter = _selectedReciter;
    if (reciter == null) return;

    final recitationId = _timing.recitationIdForReciterName(reciter.reciter);
    if (recitationId == null) {
      if (!mounted) return;
      setState(() {
        _timingRecitationId = null;
        _timingAudioUrl = null;
        _timingSegments = const [];
        _preparedAudioUrl = null;
      });
      return;
    }

    try {
      final timing = await _timing.fetchChapterTiming(
        surahNo: widget.chapter.surahNo,
        recitationId: recitationId,
      );
      final cached = await _offline.hasAudio(timing.audioUrl);
      if (!mounted) return;
      setState(() {
        _timingRecitationId = timing.recitationId;
        _timingAudioUrl = timing.audioUrl;
        _timingSegments = timing.segments;
        _preparedAudioUrl = null;
        if (cached) _cachedAudioUrls.add(timing.audioUrl);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _timingRecitationId = null;
        _timingAudioUrl = null;
        _timingSegments = const [];
        _preparedAudioUrl = null;
      });
    }
  }

  QuranReciterAudio? get _selectedReciter {
    final detail = _detail;
    if (detail == null || detail.audioByReciter.isEmpty) return null;
    if (_selectedReciterId == null) return detail.audioByReciter.first;

    for (final reciter in detail.audioByReciter) {
      if (reciter.id == _selectedReciterId) return reciter;
    }
    return detail.audioByReciter.first;
  }

  String _toBanglaDigits(String input) {
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = [
      '\u09e6',
      '\u09e7',
      '\u09e8',
      '\u09e9',
      '\u09ea',
      '\u09eb',
      '\u09ec',
      '\u09ed',
      '\u09ee',
      '\u09ef',
    ];
    var output = input;
    for (var i = 0; i < latin.length; i++) {
      output = output.replaceAll(latin[i], bangla[i]);
    }
    return output;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  int _activeAyahIndex(int totalAyah) {
    if (totalAyah <= 0) return -1;
    if (_singleAyahMode && _singleAyahIndex != null) {
      return _singleAyahIndex!.clamp(0, totalAyah - 1);
    }
    final hasPlaybackStarted = _isPlaying || _position > Duration.zero;
    if (!hasPlaybackStarted) return -1;

    if (_timingSegments.isNotEmpty) {
      final currentMs = _position.inMilliseconds;
      for (final seg in _timingSegments) {
        if (currentMs >= seg.fromMs && currentMs <= seg.toMs) {
          return seg.ayahIndex.clamp(0, totalAyah - 1);
        }
      }

      if (currentMs > _timingSegments.last.toMs) {
        return _timingSegments.last.ayahIndex.clamp(0, totalAyah - 1);
      }
      if (currentMs < _timingSegments.first.fromMs) {
        return _timingSegments.first.ayahIndex.clamp(0, totalAyah - 1);
      }
    }

    final totalMs = _duration.inMilliseconds;
    if (totalMs <= 0) return -1;
    final currentMs = _position.inMilliseconds.clamp(0, totalMs);
    final progress = currentMs / totalMs;
    final index = (progress * totalAyah).floor();
    return index.clamp(0, totalAyah - 1);
  }

  QuranTimingSegment? _timingSegmentForAyah(int ayahIndex) {
    for (final seg in _timingSegments) {
      if (seg.ayahIndex == ayahIndex) return seg;
    }
    return null;
  }

  int _activeWordIndexForAyah(int ayahIndex, String arabicText) {
    final hasPlaybackStarted = _isPlaying || _position > Duration.zero;
    if (!hasPlaybackStarted) return -1;
    if (_timingSegments.isEmpty || arabicText.trim().isEmpty) return -1;
    final timing = _timingSegmentForAyah(ayahIndex);
    if (timing == null || timing.wordSegments.isEmpty) return -1;

    final currentMs = _position.inMilliseconds;
    for (final word in timing.wordSegments) {
      if (currentMs >= word.fromMs && currentMs <= word.toMs) {
        return word.wordIndex;
      }
    }

    if (currentMs > timing.wordSegments.last.toMs) {
      return timing.wordSegments.last.wordIndex;
    }
    if (currentMs < timing.wordSegments.first.fromMs) {
      return timing.wordSegments.first.wordIndex;
    }
    return -1;
  }

  void _maybeAutoScrollToAyah(int ayahIndex) {
    if (!_isPlaying || ayahIndex < 0) return;
    if (_lastAutoScrolledAyahIndex == ayahIndex) return;
    _lastAutoScrolledAyahIndex = ayahIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _ayahItemKeys[ayahIndex];
      final context = key?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
        alignment: 0.18,
      );
    });
  }

  Key _keyForAyahItem(int ayahIndex) {
    return _ayahItemKeys.putIfAbsent(ayahIndex, GlobalKey.new);
  }

  Future<void> _loadBookmarksForCurrentSurah() async {
    final items = await _bookmarks.readBySurah(widget.chapter.surahNo);
    if (!mounted) return;
    final map = <int, QuranAyahBookmark>{};
    for (final item in items) {
      map[item.ayahNo] = item;
    }
    setState(() => _bookmarksByAyahNo = map);
  }

  QuranAyahBookmark? _bookmarkForAyah(int ayahNo) {
    return _bookmarksByAyahNo[ayahNo];
  }

  Future<void> _saveAyahBookmark({
    required int ayahNo,
    required String note,
  }) async {
    final detail = _detail;
    if (detail == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _bookmarks.upsert(
      QuranAyahBookmark(
        surahNo: detail.surahNo,
        surahName: detail.surahName,
        ayahNo: ayahNo,
        note: note,
        updatedAtMillis: now,
      ),
    );
    await _loadBookmarksForCurrentSurah();
  }

  Future<void> _removeAyahBookmark(int ayahNo) async {
    await _bookmarks.remove(surahNo: widget.chapter.surahNo, ayahNo: ayahNo);
    await _loadBookmarksForCurrentSurah();
  }

  void _scrollToAyah(int ayahIndex, {bool animated = true}) {
    final key = _ayahItemKeys[ayahIndex];
    final contextForAyah = key?.currentContext;
    if (contextForAyah == null) return;
    Scrollable.ensureVisible(
      contextForAyah,
      duration: animated ? const Duration(milliseconds: 260) : Duration.zero,
      curve: Curves.easeOutCubic,
      alignment: 0.16,
    );
  }

  void _trackLastReadAyah(int ayahNo) {
    if (ayahNo <= 0 || _lastSavedAyahNo == ayahNo) return;
    _lastSavedAyahNo = ayahNo;
    unawaited(
      _lastRead.saveLastRead(surahNo: widget.chapter.surahNo, ayahNo: ayahNo),
    );
  }

  void _jumpToInitialAyahIfNeeded() {
    if (_didJumpToInitialAyah) return;
    final initialAyahNo = widget.initialAyahNo;
    if (initialAyahNo == null || initialAyahNo <= 0) return;
    _didJumpToInitialAyah = true;
    _trackLastReadAyah(initialAyahNo);
    final ayahIndex = initialAyahNo - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      _scrollToAyah(ayahIndex, animated: false);
    });
  }

  Future<void> _openAyahBookmarkSheet(int ayahIndex) async {
    final detail = _detail;
    if (detail == null) return;
    final ayahNo = ayahIndex + 1;
    _trackLastReadAyah(ayahNo);
    final existing = _bookmarkForAyah(ayahNo);
    final noteController = TextEditingController(text: existing?.note ?? '');

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_t('Ayah', 'আয়াত')} ${_toBanglaDigits(ayahNo.toString())} ${_t('Bookmark', 'বুকমার্ক')}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: BrandColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _t(
                    'Add your note for this ayah...',
                    'এই আয়াতের জন্য আপনার নোট লিখুন...',
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FBFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: BrandColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: BrandColors.border),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  if (existing != null) ...[
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop('remove'),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(_t('Remove', 'মুছুন')),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop('save'),
                      icon: const Icon(Icons.bookmark_rounded),
                      label: Text(
                        existing == null
                            ? _t('Save Bookmark', 'বুকমার্ক সেভ করুন')
                            : _t('Update', 'আপডেট করুন'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (action == null || !mounted) {
      noteController.dispose();
      return;
    }

    if (action == 'remove') {
      await _removeAyahBookmark(ayahNo);
      if (!mounted) {
        noteController.dispose();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Bookmark removed', 'বুকমার্ক সরানো হয়েছে'))),
      );
      noteController.dispose();
      return;
    }

    final note = noteController.text.trim();
    await _saveAyahBookmark(ayahNo: ayahNo, note: note);
    if (!mounted) {
      noteController.dispose();
      return;
    }
    final message = note.isEmpty
        ? _t('Ayah bookmarked', 'আয়াত বুকমার্ক করা হয়েছে')
        : _t('Bookmark note saved', 'বুকমার্ক নোট সেভ হয়েছে');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    noteController.dispose();
  }

  Future<void> _openBookmarksScreen() async {
    final items = _bookmarksByAyahNo.values.toList(growable: false)
      ..sort((a, b) => a.ayahNo.compareTo(b.ayahNo));
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('No bookmarks in this surah', 'এই সূরায় কোনো বুকমার্ক নেই'),
          ),
        ),
      );
      return;
    }

    final selected = await Navigator.of(context).push<QuranAyahBookmark>(
      MaterialPageRoute<QuranAyahBookmark>(
        builder: (_) => QuranBookmarksScreen(bookmarks: items),
      ),
    );

    if (selected == null) return;
    final ayahIndex = selected.ayahNo - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToAyah(ayahIndex);
    });
  }

  Widget _buildArabicAyahText({
    required String arabic,
    required int highlightedWordIndex,
  }) {
    final baseStyle = TextStyle(
      fontSize: 33.sp,
      height: 1.55,
      fontWeight: FontWeight.w500,
      color: _screenTextPrimary,
    );

    final cleaned = arabic.trim();
    if (cleaned.isEmpty) {
      return const SizedBox.shrink();
    }

    if (highlightedWordIndex < 0) {
      return Text(
        cleaned,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: baseStyle,
      );
    }

    final words = cleaned.split(RegExp(r'\s+'));
    if (words.isEmpty) {
      return Text(
        cleaned,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: baseStyle,
      );
    }

    final maxWordIndex = words.length - 1;
    final safeWordIndex = highlightedWordIndex.clamp(0, maxWordIndex);

    final spans = <InlineSpan>[];
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final isHighlighted = i == safeWordIndex;
      spans.add(
        TextSpan(
          text: i == words.length - 1 ? word : '$word ',
          style: baseStyle.copyWith(
            color: isHighlighted ? _accent : _screenTextPrimary,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            backgroundColor: isHighlighted
                ? (_isDarkTheme
                      ? const Color(0x552EB8E6)
                      : const Color(0x331EA8B8))
                : Colors.transparent,
          ),
        ),
      );
    }

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      text: TextSpan(children: spans),
    );
  }

  Future<void> _onReciterChanged(int? reciterId) async {
    if (reciterId == null || reciterId == _selectedReciterId) return;
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _selectedReciterId = reciterId;
      _preparedAudioUrl = null;
      _timingRecitationId = null;
      _timingAudioUrl = null;
      _timingSegments = const [];
      _position = Duration.zero;
      _duration = Duration.zero;
      _lastAutoScrolledAyahIndex = -1;
      _resetSingleAyahPlaybackState();
    });
    await _resolveTimingForSelectedReciter();
  }

  String _playbackUrlFor(QuranReciterAudio reciter) {
    if (_timingAudioUrl != null && _timingRecitationId != null) {
      return _timingAudioUrl!;
    }
    return reciter.url;
  }

  Future<void> _prepareAudio(QuranReciterAudio reciter) async {
    final playbackUrl = _playbackUrlFor(reciter);
    final cachedFile = await _offline.getCachedAudio(playbackUrl);
    if (cachedFile != null) {
      await _player.setFilePath(cachedFile.path);
      _cachedAudioUrls.add(playbackUrl);
      return;
    }
    await _player.setUrl(playbackUrl);
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    final reciter = _selectedReciter;
    if (reciter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'No audio source found for this Surah.',
              'এই সূরার জন্য কোনো অডিও সোর্স পাওয়া যায়নি।',
            ),
          ),
        ),
      );
      return;
    }

    final playbackUrl = _playbackUrlFor(reciter);
    if (_preparedAudioUrl == playbackUrl && _player.audioSource != null) {
      setState(_resetSingleAyahPlaybackState);
      await _player.play();
      return;
    }

    setState(() => _isPreparingAudio = true);
    try {
      await _prepareAudio(reciter);
      await _player.play();
      if (!mounted) return;
      setState(() {
        _preparedAudioUrl = playbackUrl;
        _isPreparingAudio = false;
        _resetSingleAyahPlaybackState();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPreparingAudio = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Unable to play audio. Please check internet.',
              'অডিও চালানো যাচ্ছে না। ইন্টারনেট সংযোগ পরীক্ষা করুন।',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _stopAudio() async {
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _position = Duration.zero;
      _duration = Duration.zero;
      _lastAutoScrolledAyahIndex = -1;
      _resetSingleAyahPlaybackState();
    });
  }

  Future<void> _playSingleAyah(int ayahIndex) async {
    final reciter = _selectedReciter;
    if (reciter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Audio not available for this surah.',
              'এই সূরার জন্য অডিও পাওয়া যাচ্ছে না।',
            ),
          ),
        ),
      );
      return;
    }
    _trackLastReadAyah(ayahIndex + 1);

    if (_singleAyahMode && _singleAyahIndex == ayahIndex && _isPlaying) {
      await _player.pause();
      if (!mounted) return;
      setState(_resetSingleAyahPlaybackState);
      return;
    }

    final segment = _timingSegmentForAyah(ayahIndex);
    final preferredRecitationId = _timing.recitationIdForReciterName(
      reciter.reciter,
    );

    final playbackUrl = _playbackUrlFor(reciter);
    setState(() {
      _showBottomPlayer = true;
      _isPreparingAudio = true;
    });

    try {
      if (segment != null) {
        if (_preparedAudioUrl != playbackUrl || _player.audioSource == null) {
          await _prepareAudio(reciter);
          if (!mounted) return;
          setState(() => _preparedAudioUrl = playbackUrl);
        }

        final startMs = math.max(0, segment.fromMs);
        final stopMs = math.max(startMs + 80, segment.toMs - 10);
        await _player.seek(Duration(milliseconds: startMs));

        if (!mounted) return;
        setState(() {
          _singleAyahMode = true;
          _singleAyahIndex = ayahIndex;
          _singleAyahStartMs = startMs;
          _singleAyahStopMs = stopMs;
          _hifzRepeatsLeft = _targetRepeatCountForMode();
          _lastAutoScrolledAyahIndex = -1;
          _isPreparingAudio = false;
        });
        await _player.play();
        return;
      }

      final ayahAudioUrl = await _ayahAudio.fetchAyahAudioUrl(
        surahNo: widget.chapter.surahNo,
        ayahNo: ayahIndex + 1,
        preferredRecitationId: preferredRecitationId,
      );
      if (_preparedAudioUrl != ayahAudioUrl || _player.audioSource == null) {
        await _player.setUrl(ayahAudioUrl);
      } else {
        await _player.seek(Duration.zero);
      }

      if (!mounted) return;
      setState(() {
        _preparedAudioUrl = ayahAudioUrl;
        _singleAyahMode = true;
        _singleAyahIndex = ayahIndex;
        _singleAyahStartMs = 0;
        _singleAyahStopMs = null;
        _hifzRepeatsLeft = _targetRepeatCountForMode();
        _lastAutoScrolledAyahIndex = -1;
        _isPreparingAudio = false;
      });
      await _player.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPreparingAudio = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Unable to play single ayah audio right now.',
              'এই মুহূর্তে একক আয়াতের অডিও চালানো যাচ্ছে না।',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _downloadSelectedAudio() async {
    final reciter = _selectedReciter;
    if (reciter == null || _isDownloadingAudio) return;
    final playbackUrl = _playbackUrlFor(reciter);

    setState(() => _isDownloadingAudio = true);
    try {
      final path = await _offline.downloadAudio(playbackUrl);
      if (!mounted) return;
      setState(() {
        _cachedAudioUrls.add(playbackUrl);
        _isDownloadingAudio = false;
        _didDownloadAudio = true;
      });
      final fileName = path.split('\\').last.split('/').last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Audio saved: $fileName', 'অডিও সেভ হয়েছে: $fileName'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDownloadingAudio = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Audio download failed', 'অডিও ডাউনলোড ব্যর্থ')),
        ),
      );
    }
  }

  Future<void> _openAyahTafsirSheet(int ayahIndex) async {
    final detail = _detail;
    if (detail == null) return;

    final ayahNo = ayahIndex + 1;
    _trackLastReadAyah(ayahNo);
    final tafsirFuture = _tafsir.fetchBanglaTafsir(
      surahNo: detail.surahNo,
      ayahNo: ayahNo,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final sheetHeight = MediaQuery.of(sheetContext).size.height * 0.82;
        return Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: FutureBuilder<QuranAyahTafsir>(
            future: tafsirFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12.h),
                      Text(
                        'Loading and saving Bangla tafsir...',
                        style: TextStyle(color: BrandColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Ayah ${_toBanglaDigits(ayahNo.toString())} Tafsir',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: BrandColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Please check your internet connection and try again. After the first successful load, the tafsir will be saved offline for future access.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.5,
                          color: BrandColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final tafsir = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 12.w, 8.h),
                    child: Row(
                      children: [
                        Text(
                          'Ayah ${_toBanglaDigits(ayahNo.toString())} Tafsir',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: BrandColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 10.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tafsir.resourceName,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: BrandColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (tafsir.fromOfflineCache)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: BrandColors.tintBackgroundStrong,
                              borderRadius: BorderRadius.circular(999.r),
                            ),
                            child: Text(
                              'Downloaded',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: BrandColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 20.h),
                      children: [
                        SelectableText(
                          tafsir.text,
                          style: TextStyle(
                            fontSize: 16.sp,
                            height: 1.75,
                            color: BrandColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAudioCard(QuranSurahDetail detail) {
    final reciter = _selectedReciter;
    final hasReciters = detail.audioByReciter.isNotEmpty;
    final playbackUrl = reciter == null ? null : _playbackUrlFor(reciter);
    final isCached =
        playbackUrl != null && _cachedAudioUrls.contains(playbackUrl);
    final hasExactTiming =
        _timingSegments.isNotEmpty &&
        _timingAudioUrl != null &&
        _timingRecitationId != null;

    final durationMs = _duration.inMilliseconds;
    final maxMs = durationMs > 0 ? durationMs : 1;
    final currentMs = _position.inMilliseconds.clamp(0, maxMs);

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
        child: _buildGlassPanel(
          borderRadius: BorderRadius.all(Radius.circular(28.r)),
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${detail.surahName} - ${_toBanglaDigits(detail.surahNo.toString())}',
                      style: TextStyle(
                        color: _screenTextPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hide player',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _showBottomPlayer = false),
                    icon: Icon(Icons.close_rounded, color: _screenTextMuted),
                  ),
                ],
              ),
              if (_usingCachedContent) ...[
                SizedBox(height: 2.h),
                Text(
                  'Offline saved content',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: _screenTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              SizedBox(height: 6.h),
              if (hasReciters)
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Reciter',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: _glassBorder),
                    ),
                    labelStyle: TextStyle(
                      color: _screenTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      dropdownColor: _isDarkTheme
                          ? const Color(0xFF10242B)
                          : Colors.white,
                      style: TextStyle(
                        color: _screenTextPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      value: _selectedReciter?.id,
                      items: detail.audioByReciter
                          .map(
                            (reciter) => DropdownMenuItem<int>(
                              value: reciter.id,
                              child: Text(
                                reciter.reciter,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _onReciterChanged,
                    ),
                  ),
                )
              else
                Text(
                  'No audio source found for this Surah.',
                  style: TextStyle(
                    color: _isDarkTheme
                        ? const Color(0xFFDEA1A1)
                        : const Color(0xFF8F4343),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              SizedBox(height: 8.h),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: _accent,
                  inactiveTrackColor: _isDarkTheme
                      ? const Color(0x334A7D72)
                      : const Color(0xFFAED2C8),
                  thumbColor: _accent,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                ),
                child: Slider(
                  value: currentMs.toDouble(),
                  min: 0,
                  max: maxMs.toDouble(),
                  onChanged: durationMs > 0
                      ? (value) =>
                            _player.seek(Duration(milliseconds: value.round()))
                      : null,
                ),
              ),
              Row(
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _screenTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _screenTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                hasExactTiming
                    ? 'Exact ayah timing sync enabled'
                    : 'Approximate sync for this reciter',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: _screenTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: hasReciters && !_isPreparingAudio
                          ? _togglePlayPause
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: _isDarkTheme
                            ? const Color(0xFF082736)
                            : Colors.white,
                      ),
                      icon: _isPreparingAudio
                          ? SizedBox(
                              width: 16.r,
                              height: 16.r,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                      label: Text(_isPlaying ? 'Pause' : 'Play'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  OutlinedButton.icon(
                    onPressed: _isPlaying || _position > Duration.zero
                        ? _stopAudio
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _screenTextPrimary,
                      side: BorderSide(color: _glassBorder),
                    ),
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Stop'),
                  ),
                  SizedBox(width: 8.w),
                  FilledButton.tonalIcon(
                    onPressed: hasReciters && !_isDownloadingAudio
                        ? _downloadSelectedAudio
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _isDarkTheme
                          ? const Color(0xFF16353C)
                          : const Color(0xFFDAEFF5),
                      foregroundColor: _screenTextPrimary,
                    ),
                    icon: _isDownloadingAudio
                        ? SizedBox(
                            width: 16.r,
                            height: 16.r,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isCached
                                ? Icons.download_done_rounded
                                : Icons.download_rounded,
                          ),
                    label: Text(isCached ? 'Saved' : 'Offline'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahIntroCard({
    required QuranSurahDetail detail,
    required int totalAyah,
    required int activeAyahIndex,
  }) {
    final currentAyah = activeAyahIndex >= 0
        ? activeAyahIndex + 1
        : (_lastSavedAyahNo > 0 ? _lastSavedAyahNo : 1);
    final safeCurrentAyah = totalAyah <= 0
        ? 0
        : currentAyah.clamp(1, totalAyah);
    final progressValue = totalAyah <= 0 ? 0.0 : safeCurrentAyah / totalAyah;
    final ayahCountLabel = _toBanglaDigits(totalAyah.toString());
    final currentAyahLabel = _toBanglaDigits(safeCurrentAyah.toString());
    final bookmarkCount = _bookmarksByAyahNo.length;

    return _buildGlassPanel(
      borderRadius: BorderRadius.all(Radius.circular(18.r)),
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.surahNameArabicLong.trim().isEmpty
                ? detail.surahNameArabic
                : detail.surahNameArabicLong,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: _screenTextPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${detail.surahName} \u2022 ${_toBanglaDigits(detail.surahNo.toString())}',
            style: TextStyle(
              color: _screenTextSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(999.r),
            child: LinearProgressIndicator(
              minHeight: 5.h,
              value: progressValue,
              backgroundColor: _isDarkTheme
                  ? const Color(0x263A7FA1)
                  : const Color(0xFFDAEAF3),
              valueColor: AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Text(
                'Ayah $currentAyahLabel/$ayahCountLabel',
                style: TextStyle(
                  color: _screenTextPrimary,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(999.r),
                onTap: _openBookmarksScreen,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: _isDarkTheme
                        ? const Color(0x332EB8E6)
                        : const Color(0x1A1EA8B8),
                    borderRadius: BorderRadius.circular(999.r),
                    border: Border.all(color: _glassBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bookmarks_rounded, size: 14.sp, color: _accent),
                      SizedBox(width: 5.w),
                      Text(
                        '$bookmarkCount',
                        style: TextStyle(
                          color: _screenTextPrimary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAyahCard({
    Key? itemKey,
    required int index,
    required String arabic,
    required String bengali,
    required QuranAyahBookmark? bookmark,
    required bool highlighted,
    required int highlightedWordIndex,
    required VoidCallback onTap,
    required VoidCallback onPlayAyah,
    required VoidCallback onBookmarkTap,
    required bool isSingleAyahPlaying,
  }) {
    final hasBookmark = bookmark != null;
    final bookmarkNote = bookmark?.note.trim() ?? '';
    final hideBanglaInHifz = _hifzModeEnabled && _hifzHideBanglaMeaning;
    final ayahContainerBorder = highlighted
        ? const Color(0x8846BDEB)
        : (_isDarkTheme ? const Color(0x334E789D) : const Color(0xFFCCE0EE));
    final ayahContainerBg = highlighted
        ? (_isDarkTheme ? const Color(0xB01B2D33) : const Color(0xFFFCFEFF))
        : (_isDarkTheme ? const Color(0xA014242B) : const Color(0xFFFDFEFF));
    final ayahContainerGradient = _isDarkTheme
        ? null
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: highlighted
                ? const [Color(0xFFFEFFFF), Color(0xFFF3FAFF)]
                : const [Color(0xFFFEFFFF), Color(0xFFF6FBFF)],
          );
    final ayahNumberBg = highlighted
        ? (_isDarkTheme ? const Color(0xFF2EB8E6) : const Color(0xFF1EA8B8))
        : (_isDarkTheme ? const Color(0x402EB8E6) : const Color(0x331EA8B8));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          key: itemKey,
          duration: const Duration(milliseconds: 260),
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
          decoration: BoxDecoration(
            color: ayahContainerBg,
            gradient: ayahContainerGradient,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: ayahContainerBorder,
              width: highlighted ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isDarkTheme
                    ? const Color(0x26000000)
                    : const Color(0x120E3853),
                blurRadius: highlighted ? 16 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (!_isDarkTheme)
                Positioned(
                  left: -26,
                  top: -28,
                  child: IgnorePointer(
                    child: Container(
                      width: 180.w,
                      height: 74.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999.r),
                        gradient: const LinearGradient(
                          colors: [Color(0x45FFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30.r,
                        height: 30.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ayahNumberBg,
                          shape: BoxShape.circle,
                          boxShadow: highlighted
                              ? [
                                  BoxShadow(
                                    color: const Color(0x662EB8E6),
                                    blurRadius: 14,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          _toBanglaDigits((index + 1).toString()),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                            color: highlighted
                                ? (_isDarkTheme
                                      ? const Color(0xFF082734)
                                      : Colors.white)
                                : _accent,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 34.r,
                        height: 34.r,
                        decoration: BoxDecoration(
                          color: hasBookmark
                              ? (_isDarkTheme
                                    ? const Color(0x332EB8E6)
                                    : const Color(0x211EA8B8))
                              : (_isDarkTheme
                                    ? const Color(0x221D3037)
                                    : const Color(0x120E3853)),
                          borderRadius: BorderRadius.circular(999.r),
                          border: Border.all(color: _glassBorder),
                        ),
                        child: IconButton(
                          tooltip: hasBookmark
                              ? 'Edit bookmark note'
                              : 'Bookmark this ayah',
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: onBookmarkTap,
                          icon: Icon(
                            hasBookmark
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 20.sp,
                            color: hasBookmark ? _accent : _screenTextMuted,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 34.r,
                        height: 34.r,
                        decoration: BoxDecoration(
                          color: _isDarkTheme
                              ? const Color(0x2D2EB8E6)
                              : const Color(0x251EA8B8),
                          borderRadius: BorderRadius.circular(999.r),
                          border: Border.all(color: _glassBorder),
                        ),
                        child: IconButton(
                          tooltip: isSingleAyahPlaying
                              ? 'Playing this ayah'
                              : 'Play this ayah',
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: onPlayAyah,
                          icon: Icon(
                            isSingleAyahPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 21.sp,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (arabic.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildArabicAyahText(
                        arabic: arabic,
                        highlightedWordIndex: highlighted
                            ? highlightedWordIndex
                            : -1,
                      ),
                    ),
                  ],
                  if (bengali.isNotEmpty && !hideBanglaInHifz) ...[
                    SizedBox(height: 7.h),
                    Text(
                      bengali,
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.62,
                        color: _screenTextPrimary,
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 14.sp,
                        color: _screenTextMuted,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Tap for Bangla tafsir (saved offline)',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: _screenTextMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (bookmarkNote.isNotEmpty) ...[
                    SizedBox(height: 7.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: _isDarkTheme
                            ? const Color(0x332EB8E6)
                            : const Color(0x221EA8B8),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: _glassBorder),
                      ),
                      child: Text(
                        bookmarkNote,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _screenTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailForHeader = _detail;
    final headerArabicName = detailForHeader == null
        ? widget.chapter.surahNameArabic
        : (detailForHeader.surahNameArabic.trim().isEmpty
              ? widget.chapter.surahNameArabic
              : detailForHeader.surahNameArabic);
    final headerAyahTo = detailForHeader == null
        ? math.max(widget.chapter.totalAyah, 1)
        : math.max(
            detailForHeader.arabicAyahs.length,
            detailForHeader.bengaliAyahs.length,
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_didDownloadAudio);
      },
      child: Scaffold(
        backgroundColor: _bgBottom,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: _screenTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          toolbarHeight: 96,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(_didDownloadAudio),
            icon: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: _isDarkTheme
                    ? const Color(0x332EB8E6)
                    : const Color(0x1A1EA8B8),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_rounded, color: _screenTextPrimary),
            ),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                headerArabicName,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _screenTextPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 24.sp,
                  height: 1,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                widget.chapter.surahName,
                style: TextStyle(
                  color: _screenTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                ),
              ),
              Text(
                'Ayah 1-$headerAyahTo',
                style: TextStyle(
                  color: _screenTextMuted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(14),
            child: Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88.w,
                    height: 2.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999.r),
                      gradient: LinearGradient(
                        colors: [
                          _accent.withValues(alpha: 0),
                          _accent.withValues(alpha: 0.85),
                          _accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Bookmarks',
              onPressed: _openBookmarksScreen,
              icon: _bookmarksByAyahNo.isNotEmpty
                  ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 36.r,
                          height: 36.r,
                          decoration: BoxDecoration(
                            color: _isDarkTheme
                                ? const Color(0x332EB8E6)
                                : const Color(0x1A1EA8B8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.bookmarks_rounded,
                            color: _screenTextPrimary,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 8.r,
                            height: 8.r,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD54F),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: _isDarkTheme
                            ? const Color(0x332EB8E6)
                            : const Color(0x1A1EA8B8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bookmarks_outlined,
                        color: _screenTextPrimary,
                      ),
                    ),
            ),
            IconButton(
              tooltip: 'Audio player',
              onPressed: _detail == null
                  ? null
                  : () => setState(() => _showBottomPlayer = true),
              icon: Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: _isDarkTheme
                      ? const Color(0x332EB8E6)
                      : const Color(0x1A1EA8B8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.headphones_rounded,
                  color: _screenTextPrimary,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _detail != null && _showBottomPlayer
            ? _buildAudioCard(_detail!)
            : null,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bgTop, _bgMid, _bgBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                left: -90,
                child: Container(
                  width: 250.r,
                  height: 250.r,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x332EB8E6), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 220.h,
                right: -110,
                child: Container(
                  width: 260.r,
                  height: 260.r,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x222EB8E6), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Center(child: CircularProgressIndicator(color: _accent))
              else if (_error != null)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _screenTextPrimary),
                      ),
                      SizedBox(height: 10.h),
                      FilledButton(
                        onPressed: _loadSurahDetail,
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: _isDarkTheme
                              ? const Color(0xFF082736)
                              : Colors.white,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    final detail = _detail!;
                    final totalAyah = math.max(
                      detail.arabicAyahs.length,
                      math.max(
                        detail.bengaliAyahs.length,
                        detail.englishAyahs.length,
                      ),
                    );
                    final activeAyahIndex = _activeAyahIndex(totalAyah);
                    _maybeAutoScrollToAyah(activeAyahIndex);
                    _jumpToInitialAyahIfNeeded();
                    if (activeAyahIndex >= 0) {
                      _trackLastReadAyah(activeAyahIndex + 1);
                    }

                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        10,
                        16,
                        _showBottomPlayer ? 20 : 24,
                      ),
                      itemCount: totalAyah + 1,
                      separatorBuilder: (_, index) =>
                          SizedBox(height: index == 0 ? 12 : 10),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildSurahIntroCard(
                            detail: detail,
                            totalAyah: totalAyah,
                            activeAyahIndex: activeAyahIndex,
                          );
                        }

                        final ayahIndex = index - 1;
                        final arabic = ayahIndex < detail.arabicAyahs.length
                            ? detail.arabicAyahs[ayahIndex]
                            : '';
                        final bangla = ayahIndex < detail.bengaliAyahs.length
                            ? _repairMojibake(detail.bengaliAyahs[ayahIndex])
                            : '';
                        final english = ayahIndex < detail.englishAyahs.length
                            ? _repairMojibake(detail.englishAyahs[ayahIndex])
                            : '';
                        final useEnglishTranslation =
                            _translationLanguage.toLowerCase() == 'english';
                        final translation = !_showTranslation
                            ? ''
                            : (useEnglishTranslation
                                  ? (english.isEmpty ? bangla : english)
                                  : bangla);
                        final bookmark = _bookmarkForAyah(ayahIndex + 1);
                        final wordHighlightIndex = _activeWordIndexForAyah(
                          ayahIndex,
                          arabic,
                        );

                        return _buildAyahCard(
                          itemKey: _keyForAyahItem(ayahIndex),
                          index: ayahIndex,
                          arabic: arabic,
                          bengali: translation,
                          bookmark: bookmark,
                          highlighted: ayahIndex == activeAyahIndex,
                          highlightedWordIndex: wordHighlightIndex,
                          onTap: () => _openAyahTafsirSheet(ayahIndex),
                          onPlayAyah: () => _playSingleAyah(ayahIndex),
                          onBookmarkTap: () =>
                              _openAyahBookmarkSheet(ayahIndex),
                          isSingleAyahPlaying:
                              _singleAyahMode &&
                              _singleAyahIndex == ayahIndex &&
                              _isPlaying,
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
