part of '../screens/surah_detail_screen.dart';

/// Reciter switching, single-ayah playback and offline audio download.
mixin SurahDetailSingleAyahMixin
    on
        State<SurahDetailScreen>,
        SurahDetailStateMixin,
        SurahDetailAudioMixin,
        SurahDetailBookmarkMixin,
        SurahDetailDataMixin {
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

  Future<void> _playSingleAyah(int ayahIndex) async {
    final reciter = _selectedReciter;
    if (reciter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Audio not available for this surah.',
              'এই সূরার জন্য অডিও পাওয়া যাচ্ছে না।',
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
              'এই মুহূর্তে একক আয়াতের অডিও চালানো যাচ্ছে না।',
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
            _t('Audio saved: $fileName', 'অডিও সেভ হয়েছে: $fileName'),
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
}
