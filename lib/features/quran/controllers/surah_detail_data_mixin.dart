part of '../screens/surah_detail_screen.dart';

/// Lifecycle, surah/timing loading and active-ayah resolution.
mixin SurahDetailDataMixin
    on
        State<SurahDetailScreen>,
        SurahDetailStateMixin,
        SurahDetailAudioMixin,
        SurahDetailBookmarkMixin {
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
          'সূরার বিস্তারিত লোড করা যায়নি। একবার ইন্টারনেটে যুক্ত হয়ে আবার চেষ্টা করুন।',
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
}
