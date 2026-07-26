part of '../screens/daily_activity_screen.dart';

mixin DailyControllerLoadersMixin on State<DailyActivityScreen>, DailyControllerLocationMixin {
  void _initializeMiniCompass() {
    _homeCompassSub?.cancel();
    final stream = FlutterCompass.events;
    if (stream == null) {
      _homeHeading = null;
      return;
    }

    _homeCompassSub = stream.listen(
      (event) {
        final heading = event.heading;
        if (heading == null || heading.isNaN) return;
        _safeSetState(() {
          _homeHeading = _normalizeDegrees(heading);
        });
      },
      onError: (_) {
        _safeSetState(() => _homeHeading = null);
      },
    );
  }

  Future<void> _loadLastReadCard() async {
    if (!kQuranFeatureEnabled) {
      if (!mounted) return;
      _safeSetState(() {
        _lastReadSurahNo = null;
        _lastReadChapter = null;
      });
      return;
    }

    final savedSurahNo = await _lastReadService.readLastReadSurahNo();
    if (!mounted) return;

    if (savedSurahNo == null) {
      _safeSetState(() {
        _lastReadSurahNo = null;
        _lastReadChapter = null;
      });
      return;
    }

    QuranChapter? chapter;
    try {
      final chapters = await _quranApiService.fetchChapters();
      for (final item in chapters) {
        if (item.surahNo == savedSurahNo) {
          chapter = item;
          break;
        }
      }
    } catch (_) {
      // Keep number fallback when chapter metadata is unavailable.
    }

    if (!mounted) return;
    _safeSetState(() {
      _lastReadSurahNo = savedSurahNo;
      _lastReadChapter = chapter;
    });
  }

  Future<void> _openLastRead() async {
    if (!kQuranFeatureEnabled) {
      await Navigator.of(context).pushNamed(RouteNames.discover);
      return;
    }

    final chapter = _lastReadChapter;
    if (chapter != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SurahDetailScreen(chapter: chapter),
        ),
      );
      return;
    }

    await Navigator.of(context).pushNamed(RouteNames.quran);
    if (!mounted) return;
    await _loadLastReadCard();
  }




  /// Loads today's tracked amal score from local storage so the home card
  /// reflects progress made on the Amol tracker. Safe to call repeatedly.
  Future<void> _loadAmolProgress() async {
    await _amolTrackService.load();
    _onAmolProgressChanged();
  }

  /// Syncs the home card with the shared tracker store. Invoked instantly
  /// whenever a deed is toggled (on the tracker or anywhere) via the service's
  /// [AmolTrackService.revision] notifier.
  void _onAmolProgressChanged() {
    if (!mounted) return;
    final score = _amolTrackService.scoreFor(DateTime.now());
    if (score == _amolScoreToday) return;
    setState(() => _amolScoreToday = score);
  }

}
