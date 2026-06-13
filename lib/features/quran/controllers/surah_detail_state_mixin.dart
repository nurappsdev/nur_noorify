part of '../screens/surah_detail_screen.dart';

/// Core state, theme tokens and small shared helpers for [SurahDetailScreen].
mixin SurahDetailStateMixin on State<SurahDetailScreen> {
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
      '০',
      '১',
      '২',
      '৩',
      '৪',
      '৫',
      '৬',
      '৭',
      '৮',
      '৯',
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

  String _playbackUrlFor(QuranReciterAudio reciter) {
    if (_timingAudioUrl != null && _timingRecitationId != null) {
      return _timingAudioUrl!;
    }
    return reciter.url;
  }

  Key _keyForAyahItem(int ayahIndex) {
    return _ayahItemKeys.putIfAbsent(ayahIndex, GlobalKey.new);
  }
}
