part of '../screens/surah_detail_screen.dart';

/// Audio player stream binding and play/pause/stop control.
mixin SurahDetailAudioMixin on State<SurahDetailScreen>, SurahDetailStateMixin {
  void _onReadingPreferenceChanged() {
    if (!mounted) return;
    setState(() {});
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
              'এই সূরার জন্য কোনো অডিও সোর্স পাওয়া যায়নি।',
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
}
