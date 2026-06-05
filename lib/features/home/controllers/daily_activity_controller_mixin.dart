part of '../screens/daily_activity_screen.dart';

mixin DailyActivityControllerMixin on State<DailyActivityScreen> {
  static const _kaabaLat = 21.422487;
  static const _kaabaLng = 39.826206;
  static const _baitulMukarramLat = 23.7286;
  static const _baitulMukarramLng = 90.4106;
  static const _baitulMukarramLabel = 'Baitul Mukarram, Dhaka';
  static const _apiMethod = 1; // University of Islamic Sciences, Karachi
  static const _apiSchool = 1; // Hanafi
  static const _prayerCarouselSeed = 1000;
  static const _prayerCarouselItemCount = 10000;

  late final Timer _clockTimer;
  DateTime _now = DateTime.now();
  // Incremented each time the home tab becomes visible again so the sun/moon
  // arc replays its sunrise/Maghrib → now sweep.
  int _arcReplayTick = 0;
  BottomNavProvider? _bottomNavProvider;
  double? _latitude;
  double? _longitude;
  bool _isFetchingPrayerSchedule = false;
  bool _ignoreNextLocationToggleChange = false;
  DailyPrayerSchedule? _todaySchedule;
  DailyPrayerSchedule? _tomorrowSchedule;
  DateTime? _lastPrayerCalcDate;
  DateTime? _nextSehriAt;
  DateTime? _nextIftarAt;
  bool _isRefreshingLocation = false;
  String _locationLabel = _baitulMukarramLabel;
  String _countdownLabel = 'Fajr in --:--:--';
  String _activePrayer = 'Zuhr';
  Duration _activeRemaining = Duration.zero;
  double _activeProgress = 0.0;
  Map<String, String> _prayerTimes = const {
    'Fajr': '--:--',
    'Zuhr': '--:--',
    'Asr': '--:--',
    'Maghrib': '--:--',
    'Isha': '--:--',
  };

  StreamSubscription<CompassEvent>? _homeCompassSub;
  double? _homeHeading;
  double? _homeQiblaBearing;
  final List<String> _prayerOrder = const [
    'Fajr',
    'Zuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];
  late final PageController _prayerPageController;
  String? _selectedPrayer;
  final QuranLastReadService _lastReadService = QuranLastReadService();
  final QuranApiService _quranApiService = QuranApiService();
  final MosqueResultsCacheService _mosqueResultsCacheService =
      MosqueResultsCacheService();
  final Dio _prayerApi = Dio(
    BaseOptions(
      baseUrl: 'https://api.aladhan.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );
  int? _lastReadSurahNo;
  QuranChapter? _lastReadChapter;

  final List<ActivityItem> _activities = [
    ActivityItem(title: 'Alms', done: 4, total: 10),
    ActivityItem(title: 'Recite the Al Quran', done: 8, total: 10),
  ];
  final AmolTrackService _amolTrackService = AmolTrackService();
  int _amolCompletedToday = 0;
  List<MosqueItem> _nearbyMosquePreview = const [];
  DateTime? _nearbyMosquePreviewUpdatedAt;
  bool _announcementModalChecked = false;
  bool _announcementModalFetchInProgress = false;
  static String? _lastShownAnnouncementId;

  void initializeDailyActivityController() {
    _prayerPageController = PageController(
      viewportFraction: 0.34,
      initialPage: _carouselIndexForPrayer(_activePrayer),
    );
    _setBaitulMukarramLocation();
    _seedInitialPrayerPreview();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The home screen lives in an always-alive IndexedStack, so initState
      // never re-runs when switching tabs. Listen to the bottom-nav index and
      // replay the sky arc each time the home tab (index 0) is reopened.
      final navProvider = context.read<BottomNavProvider>();
      _bottomNavProvider = navProvider;
      navProvider.addListener(_onBottomNavChanged);
      if (_selectedPrayer == null) {
        _syncPrayerPageToActive(animate: false);
      }
    });
    appLanguageNotifier.addListener(_onLanguageChanged);
    useDeviceLocationNotifier.addListener(_onUseDeviceLocationChanged);
    profileLocationNotifier.addListener(_onProfileLocationChanged);
    prayerAlertsEnabledNotifier.addListener(_onPrayerAlertToggleChanged);
    sehriAlertEnabledNotifier.addListener(_onSehriAlertToggleChanged);
    iftarAlertEnabledNotifier.addListener(_onIftarAlertToggleChanged);
    tahajjudAlertEnabledNotifier.addListener(_onTahajjudAlertToggleChanged);
    alertToneNotifier.addListener(_onAlertToneChanged);
    _initializeMiniCompass();
    _loadPrayerData();
    unawaited(ensureNotificationPermissions());
    if (kQuranFeatureEnabled) {
      _loadLastReadCard();
    }
    unawaited(_loadNearbyMosquePreview());
    unawaited(_showAnnouncementModalIfNeeded());
    _amolTrackService.revision.addListener(_onAmolProgressChanged);
    unawaited(_loadAmolProgress());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _safeSetState(() => _now = DateTime.now());
      _updateCountdown();
      if (_lastPrayerCalcDate == null ||
          _lastPrayerCalcDate!.day != _now.day ||
          _lastPrayerCalcDate!.month != _now.month ||
          _lastPrayerCalcDate!.year != _now.year) {
        _recalculatePrayerTimesForToday();
      }
    });
  }

  void _seedInitialPrayerPreview() {
    final today = DateTime(_now.year, _now.month, _now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todaySchedule = _buildFallbackSchedule(today);
    final tomorrowSchedule = _buildFallbackSchedule(tomorrow);

    final activeData = _buildActivePrayerData(
      now: _now,
      fajr: todaySchedule.fajr,
      dzuhr: todaySchedule.dzuhr,
      ashr: todaySchedule.ashr,
      maghrib: todaySchedule.maghrib,
      isha: todaySchedule.isha,
      ishaBefore: todaySchedule.isha.subtract(const Duration(days: 1)),
    );

    final mealData = _buildRamadanMealData(
      now: _now,
      sehri: todaySchedule.imsak,
      maghrib: todaySchedule.maghrib,
      tomorrowSehri: tomorrowSchedule.imsak,
      tomorrowMaghrib: tomorrowSchedule.maghrib,
    );

    _todaySchedule = todaySchedule;
    _tomorrowSchedule = tomorrowSchedule;
    _lastPrayerCalcDate = today;
    _prayerTimes = {
      'Fajr': _formatPrayerTime(todaySchedule.fajr),
      'Zuhr': _formatPrayerTime(todaySchedule.dzuhr),
      'Asr': _formatPrayerTime(todaySchedule.ashr),
      'Maghrib': _formatPrayerTime(todaySchedule.maghrib),
      'Isha': _formatPrayerTime(todaySchedule.isha),
    };
    _activePrayer = activeData.name;
    _countdownLabel = activeData.countdownLabel;
    _activeRemaining = activeData.remaining;
    _activeProgress = activeData.progress;
    _nextSehriAt = mealData.nextSehri;
    _nextIftarAt = mealData.nextIftar;
  }

  void disposeDailyActivityController() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    useDeviceLocationNotifier.removeListener(_onUseDeviceLocationChanged);
    profileLocationNotifier.removeListener(_onProfileLocationChanged);
    prayerAlertsEnabledNotifier.removeListener(_onPrayerAlertToggleChanged);
    sehriAlertEnabledNotifier.removeListener(_onSehriAlertToggleChanged);
    iftarAlertEnabledNotifier.removeListener(_onIftarAlertToggleChanged);
    tahajjudAlertEnabledNotifier.removeListener(_onTahajjudAlertToggleChanged);
    alertToneNotifier.removeListener(_onAlertToneChanged);
    _amolTrackService.revision.removeListener(_onAmolProgressChanged);
    _bottomNavProvider?.removeListener(_onBottomNavChanged);
    _homeCompassSub?.cancel();
    _clockTimer.cancel();
    _prayerPageController.dispose();
  }

  void _onBottomNavChanged() {
    // Home is index 0. Replaying only when it becomes active keeps the sweep
    // tied to "opening" the screen rather than every tab change.
    if (_bottomNavProvider?.currentIndex != 0) return;
    _safeSetState(() => _arcReplayTick++);
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _showAnnouncementModalIfNeeded() async {
    if (_announcementModalChecked || _announcementModalFetchInProgress) return;
    if (Firebase.apps.isEmpty) {
      _announcementModalChecked = true;
      return;
    }
    final hasInternet = await NetworkUtils.hasInternet();
    if (!hasInternet) {
      _announcementModalChecked = true;
      return;
    }
    _announcementModalFetchInProgress = true;
    try {
      final announcement = await AnnouncementService.instance
          .fetchLatestActiveModalAnnouncement();
      if (!mounted) return;
      if (!_isCurrentRouteActive()) return;
      _announcementModalChecked = true;
      if (announcement == null) return;
      if (_lastShownAnnouncementId == announcement.id) return;
      _lastShownAnnouncementId = announcement.id;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_isCurrentRouteActive()) return;
        _openAnnouncementDialog(announcement);
      });
    } catch (e) {
      debugPrint('Announcement modal loading failed: $e');
    } finally {
      _announcementModalFetchInProgress = false;
    }
  }

  void _openAnnouncementDialog(AnnouncementItem item) {
    if (!_isCurrentRouteActive()) return;
    final title = item.localizedTitle(_isBangla);
    final message = item.localizedMessage(_isBangla);
    final posterUrl = item.posterUrl?.trim();
    final hasPoster = _isNetworkImageUrl(posterUrl);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            title.isEmpty
                ? (_isBangla
                      ? '\u0997\u09c1\u09b0\u09c1\u09a4\u09cd\u09ac\u09aa\u09c2\u09b0\u09cd\u09a3 \u0998\u09cb\u09b7\u09a3\u09be'
                      : 'Important Announcement')
                : title,
          ),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasPoster) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    message.isEmpty
                        ? (_isBangla
                              ? '\u09a8\u09a4\u09c1\u09a8 \u0986\u09aa\u09a1\u09c7\u099f \u09aa\u09c7\u09a4\u09c7 \u0986\u09ae\u09be\u09a6\u09c7\u09b0 \u09b8\u09be\u09a5\u09c7 \u09a5\u09be\u0995\u09c1\u09a8\u0964'
                              : 'Stay connected for the latest app update.')
                        : message,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                _isBangla
                    ? '\u09ac\u09a8\u09cd\u09a7 \u0995\u09b0\u09c1\u09a8'
                    : 'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isCurrentRouteActive() {
    final route = ModalRoute.of(context);
    return route?.isCurrent ?? true;
  }

  bool _isNetworkImageUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

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

  void _updateHomeQiblaBearing(double lat, double lng) {
    _homeQiblaBearing = _calculateQiblaBearingBasic(lat: lat, lng: lng);
  }

  double _calculateQiblaBearingBasic({
    required double lat,
    required double lng,
  }) {
    final latRad = lat * math.pi / 180;
    final lngRad = lng * math.pi / 180;
    final kaabaLatRad = _kaabaLat * math.pi / 180;
    final kaabaLngRad = _kaabaLng * math.pi / 180;
    final dLng = kaabaLngRad - lngRad;

    final y = math.sin(dLng);
    final x =
        math.cos(latRad) * math.tan(kaabaLatRad) -
        math.sin(latRad) * math.cos(dLng);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return _normalizeDegrees(bearing);
  }

  double _normalizeDegrees(double degrees) {
    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double _signedQiblaDelta(double target, double current) {
    return ((target - current + 540) % 360) - 180;
  }

  void _onLanguageChanged() {
    _safeSetState(() {});
  }

  void _onProfileLocationChanged() {
    if (useDeviceLocationNotifier.value) return;
    final label = _profileOrFallbackLocationLabel();
    if (_locationLabel == label) return;
    _safeSetState(() => _locationLabel = label);
  }

  Future<void> _onUseDeviceLocationChanged() async {
    if (_ignoreNextLocationToggleChange) {
      _ignoreNextLocationToggleChange = false;
      return;
    }
    await _loadPrayerData();
    _safeSetState(() {});
  }

  void _setUseDeviceLocationSilently(bool value) {
    if (useDeviceLocationNotifier.value == value) return;
    _ignoreNextLocationToggleChange = true;
    useDeviceLocationNotifier.value = value;
  }

  Future<void> _onSehriAlertToggleChanged() async {
    if (sehriAlertEnabledNotifier.value) {
      if (_nextSehriAt != null) {
        await _scheduleSehriNotification(_nextSehriAt!);
      }
    } else {
      await _cancelSehriNotification();
    }
    _safeSetState(() {});
  }

  Future<void> _onPrayerAlertToggleChanged() async {
    await _refreshPrayerAlertScheduling();
    _safeSetState(() {});
  }

  Future<void> _onIftarAlertToggleChanged() async {
    if (iftarAlertEnabledNotifier.value) {
      if (_nextIftarAt != null) {
        await _scheduleIftarNotification(_nextIftarAt!);
      }
    } else {
      await _cancelIftarNotification();
    }
    _safeSetState(() {});
  }

  Future<void> _onTahajjudAlertToggleChanged() async {
    if (tahajjudAlertEnabledNotifier.value) {
      final at = _nextTahajjudTimeForSchedule();
      if (at != null) {
        await _scheduleTahajjudNotification(at);
      }
    } else {
      await _cancelTahajjudNotification();
    }
    _safeSetState(() {});
  }

  void _onAlertToneChanged() {
    unawaited(_refreshAllAlertSchedulesForToneChange());
    _safeSetState(() {});
  }

  Future<void> _refreshAllAlertSchedulesForToneChange() async {
    await _refreshPrayerAlertScheduling();
    await _refreshMealAlertScheduling();
    await _refreshTahajjudAlertScheduling();
  }

  /// Night runs from this evening's Maghrib to the next dawn (Fajr). When it is
  /// already past midnight but before Fajr, the night began the previous
  /// evening, so Maghrib is rewound by a day.
  ({DateTime start, DateTime end})? _currentNightWindow() {
    final today = _todaySchedule;
    if (today == null) return null;
    final fajrToday = today.fajr;
    final maghribToday = today.maghrib;
    if (_now.isBefore(fajrToday)) {
      return (
        start: maghribToday.subtract(const Duration(days: 1)),
        end: fajrToday,
      );
    }
    if (_now.isAfter(maghribToday)) {
      final fajrNext =
          _tomorrowSchedule?.fajr ?? fajrToday.add(const Duration(days: 1));
      return (start: maghribToday, end: fajrNext);
    }
    return null;
  }

  bool get _isNightTime => _currentNightWindow() != null;

  /// Fraction of the current night already elapsed (0 at Maghrib, 1 at Fajr).
  double _nightProgress() {
    final window = _currentNightWindow();
    if (window == null) return 0.0;
    final total = window.end.difference(window.start).inSeconds;
    if (total <= 0) return 0.0;
    final elapsed = _now.difference(window.start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Start of the last third of the current night — the recommended onset of
  /// Tahajjud. Null during daytime.
  DateTime? _tahajjudTime() {
    final window = _currentNightWindow();
    if (window == null) return null;
    final total = window.end.difference(window.start);
    return window.start.add(total * 2 ~/ 3);
  }

  bool _isLastThirdOfNight() {
    final window = _currentNightWindow();
    final tahajjud = _tahajjudTime();
    if (window == null || tahajjud == null) return false;
    return !_now.isBefore(tahajjud) && _now.isBefore(window.end);
  }

  /// Tonight's Tahajjud onset, computed independently of the current time so it
  /// can be scheduled from anywhere in the day.
  DateTime? _nextTahajjudTimeForSchedule() {
    final today = _todaySchedule;
    if (today == null) return null;
    final start = today.maghrib;
    final end =
        _tomorrowSchedule?.fajr ?? today.fajr.add(const Duration(days: 1));
    if (!end.isAfter(start)) return null;
    return start.add(end.difference(start) * 2 ~/ 3);
  }

  static const Map<String, ({String am, String pm})> _meridiemLabels = {
    'en': (am: 'AM', pm: 'PM'),
    'bn': (am: 'পূর্বাহ্ণ', pm: 'অপরাহ্ণ'),
    'ar': (am: 'ص', pm: 'م'),
  };

  String _localizedMeridiem(bool isAm) {
    final code = _isBangla ? 'bn' : 'en';
    final labels = _meridiemLabels[code] ?? _meridiemLabels['en']!;
    return isAm ? labels.am : labels.pm;
  }

  /// Loads today's tracked-deed count from local storage so the home card
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
    final count = _amolTrackService.completedCountFor(DateTime.now());
    if (count == _amolCompletedToday) return;
    setState(() => _amolCompletedToday = count);
  }

  String get _formattedTime {
    final hour12 = (_now.hour % 12 == 0) ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final meridiem = _localizedMeridiem(_now.hour < 12);
    final value = '$hour12:$minute';
    return _isBangla
        ? '${_toBanglaDigits(value)} $meridiem'
        : '$value $meridiem';
  }

  /// Same as [_formattedTime] but with a live, ticking seconds component. The
  /// clock timer rebuilds every second, so the seconds advance in real time.
  String get _formattedTimeWithSeconds {
    final hour12 = (_now.hour % 12 == 0) ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    final meridiem = _localizedMeridiem(_now.hour < 12);
    final value = '$hour12:$minute:$second';
    return _isBangla
        ? '${_toBanglaDigits(value)} $meridiem'
        : '$value $meridiem';
  }

  String get _formattedHijriDate {
    final hijri = HijriCalendar.fromDate(_now);
    final day = hijri.hDay.toString();
    final year = hijri.hYear.toString();
    final monthName = _localizedHijriMonth(hijri.hMonth);

    if (_isBangla) {
      return '${_toBanglaDigits(day)} $monthName ${_toBanglaDigits(year)} \u09b9\u09bf\u099c\u09b0\u09bf';
    }
    return '$day $monthName $year H';
  }

  String get _formattedBanglaDate {
    return Ponjika.format(date: _now, format: 'DD MM YY');
  }

  String get _formattedBritishDate {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final day = _now.day.toString().padLeft(2, '0');
    final value = '$day ${months[_now.month - 1]} ${_now.year}';
    return _isBangla ? _toBanglaDigits(value) : value;
  }

  List<String> get _headerDateVariants {
    final banglaLabel = _isBangla ? '\u09ac\u09be\u0982\u09b2\u09be' : 'Bangla';
    final hijriLabel = _isBangla ? '\u0986\u09b0\u09ac\u09bf' : 'Hijri';
    final britishLabel = _isBangla
        ? '\u0987\u0982\u09b0\u09c7\u099c\u09bf'
        : 'English (UK)';
    return [
      '$banglaLabel: $_formattedBanglaDate',
      '$hijriLabel: $_formattedHijriDate',
      '$britishLabel: $_formattedBritishDate',
    ];
  }

  String get _activeHeaderDate {
    final variants = _headerDateVariants;
    final index = (_now.millisecondsSinceEpoch ~/ 5000) % variants.length;
    return variants[index];
  }

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

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

  String _localizedPrayerName(String name) {
    if (!_isBangla) return name;
    const map = {
      'Fajr': '\u09ab\u099c\u09b0',
      'Zuhr': '\u09af\u09cb\u09b9\u09b0',
      'Asr': '\u0986\u09b8\u09b0',
      'Maghrib': '\u09ae\u09be\u0997\u09b0\u09bf\u09ac',
      'Isha': '\u0987\u09b6\u09be',
    };
    return map[name] ?? name;
  }

  String _arabicPrayerName(String name) {
    const map = {
      'Fajr': '\u0627\u0644\u0641\u062c\u0631',
      'Zuhr': '\u0627\u0644\u0638\u0647\u0631',
      'Asr': '\u0627\u0644\u0639\u0635\u0631',
      'Maghrib': '\u0627\u0644\u0645\u063a\u0631\u0628',
      'Isha': '\u0627\u0644\u0639\u0634\u0627\u0621',
    };
    return map[name] ?? '';
  }

  static const Map<String, List<String>> _hijriMonths = {
    'bn': [
      'মুহাররম',
      'সফর',
      'রবিউল আউয়াল',
      'রবিউস সানি',
      'জমাদিউল আউয়াল',
      'জমাদিউস সানি',
      'রজব',
      'শাবান',
      'রমজান',
      'শাওয়াল',
      'জিলকদ',
      'জিলহজ্জ',
    ],
    'en': [
      'Muharram',
      'Safar',
      'Rabiul Awwal',
      'Rabius Sani',
      'Jamadial Awwal',
      'Jamadias Sani',
      'Rajab',
      'Shaban',
      'Ramadan',
      'Shawwal',
      'Zilkad',
      'Zilhajj',
    ],
    'ar': [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ],
  };

  /// Localized Hijri month name for [month] (1-12) in the active language.
  String _localizedHijriMonth(int month) {
    final code = _isBangla ? 'bn' : 'en';
    final names = _hijriMonths[code] ?? _hijriMonths['en']!;
    if (month < 1 || month > names.length) return '';
    return names[month - 1];
  }

  String _localizedCountdownLabel() {
    final parts = _countdownLabel.split(' in ');
    if (parts.length == 2) {
      final name = _localizedPrayerName(parts[0]);
      final value = _isBangla ? _toBanglaDigits(parts[1]) : parts[1];
      // The countdown now tracks the end of the current prayer window.
      return _isBangla
          ? '$name \u09b6\u09c7\u09b7 \u09b9\u09a4\u09c7 $value'
          : '$name ends in $value';
    }
    return _isBangla ? _toBanglaDigits(_countdownLabel) : _countdownLabel;
  }

  String _localizedActiveRemainingLabel() => _isBangla
      ? '\u09b6\u09c7\u09b7 \u09b9\u0993\u09df\u09be\u09b0 \u09ac\u09be\u0995\u09bf'
      : 'Time Left';

  String _localizedPrayerTimeLabel() => _isBangla
      ? '\u09aa\u09cd\u09b0\u09be\u09b0\u09cd\u09a5\u09a8\u09be\u09b0 \u09b8\u09ae\u09df'
      : 'Prayer Time';

  String _localizedSehriAlertTitle() => _isBangla
      ? '\u09b8\u09c7\u09b9\u09b0\u09bf \u098f\u09b2\u09be\u09b0\u09cd\u099f'
      : 'Sehri Alert';

  String _localizedSehriAlertBody() => _isBangla
      ? '\u09b8\u09c7\u09b9\u09b0\u09bf\u09b0 \u09b8\u09ae\u09df \u09b9\u09df\u09c7\u099b\u09c7\u0964'
      : 'It is time for Sehri.';

  String _localizedIftarAlertTitle() => _isBangla
      ? '\u0987\u09ab\u09a4\u09be\u09b0 \u098f\u09b2\u09be\u09b0\u09cd\u099f'
      : 'Iftar Alert';

  String _localizedIftarAlertBody() => _isBangla
      ? '\u0987\u09ab\u09a4\u09be\u09b0\u09c7\u09b0 \u09b8\u09ae\u09df \u09b9\u09df\u09c7\u099b\u09c7\u0964'
      : 'It is time for Iftar.';

  String _localizedTahajjudAlertTitle() => _isBangla
      ? '\u09a4\u09be\u09b9\u09be\u099c\u09cd\u099c\u09c1\u09a6\u09c7\u09b0 \u09b8\u09ae\u09af\u09bc'
      : 'Tahajjud Reminder';

  String _localizedTahajjudAlertBody() => _isBangla
      ? '\u09b0\u09be\u09a4\u09c7\u09b0 \u09b6\u09c7\u09b7 \u09a4\u09c3\u09a4\u09c0\u09af\u09bc\u09be\u0982\u09b6 \u2014 \u09a4\u09be\u09b9\u09be\u099c\u09cd\u099c\u09c1\u09a6 \u0993 \u09a6\u09cb\u09af\u09bc\u09be\u09b0 \u09b6\u09cd\u09b0\u09c7\u09b7\u09cd\u09a0 \u09b8\u09ae\u09af\u09bc\u0964 \u0986\u09b2\u09cd\u09b2\u09be\u09b9 \u098f\u0996\u09a8 \u09b8\u09ac\u099a\u09c7\u09af\u09bc\u09c7 \u09a8\u09bf\u0995\u099f\u09ac\u09b0\u09cd\u09a4\u09c0\u0964'
      : 'The last third of the night has begun \u2014 the finest time for Tahajjud and dua. Your Lord is nearest now.';

  String _localizedPrayerTime(String value) =>
      _isBangla ? _toBanglaDigits(value) : value;

  String _localizedNextSehriLabel() =>
      _isBangla ? '\u09b8\u09c7\u09b9\u09b0\u09bf' : 'Sehri';

  String _localizedNextIftarLabel() =>
      _isBangla ? '\u0987\u09ab\u09a4\u09be\u09b0' : 'Iftar';

  String _localizedRemainingLabel() => _isBangla
      ? '\u0985\u09ac\u09b6\u09bf\u09b7\u09cd\u099f \u09b8\u09ae\u09df'
      : 'Remaining';

  String _localizedLastReadLabel() => _isBangla
      ? '\u09b8\u09b0\u09cd\u09ac\u09b6\u09c7\u09b7 \u09a4\u09bf\u09b2\u09be\u0993\u09df\u09be\u09a4'
      : 'Last Read';

  String _localizedContinueLabel() => _isBangla
      ? '\u099a\u09be\u09b2\u09bf\u09df\u09c7 \u09af\u09be\u09a8'
      : 'Continue';

  String _lastReadPrimaryLine() {
    final chapter = _lastReadChapter;
    if (chapter != null) {
      final surahNo = _isBangla
          ? _toBanglaDigits(chapter.surahNo.toString())
          : chapter.surahNo.toString();
      return _isBangla
          ? '${chapter.surahName} • \u09b8\u09c2\u09b0\u09be $surahNo'
          : '${chapter.surahName} • Surah $surahNo';
    }

    if (_lastReadSurahNo != null) {
      final surahNo = _isBangla
          ? _toBanglaDigits(_lastReadSurahNo.toString())
          : _lastReadSurahNo.toString();
      return _isBangla ? '\u09b8\u09c2\u09b0\u09be $surahNo' : 'Surah $surahNo';
    }

    return _isBangla
        ? '\u09b8\u09be\u09ae\u09cd\u09aa\u09cd\u09b0\u09a4\u09bf\u0995 \u09a4\u09bf\u09b2\u09be\u0993\u09df\u09be\u09a4 \u09a8\u09c7\u0987'
        : 'No recent recitation';
  }

  String? _lastReadSecondaryLine() {
    final chapter = _lastReadChapter;
    if (chapter == null) return null;
    if (chapter.surahNameTranslation.trim().isEmpty) return null;
    return chapter.surahNameTranslation;
  }

  String _localizedTimeOrPlaceholder(DateTime? time) {
    if (time == null) return '--:--';
    return _localizedPrayerTime(_formatPrayerTime(time));
  }

  String _formattedIftarRemaining() {
    if (_nextIftarAt == null) return '--:--:--';
    final remaining = _nextIftarAt!.difference(_now);
    final safe = remaining.isNegative ? Duration.zero : remaining;
    final hh = safe.inHours.toString().padLeft(2, '0');
    final mm = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (safe.inSeconds % 60).toString().padLeft(2, '0');
    final value = '$hh:$mm:$ss';
    return _isBangla ? _toBanglaDigits(value) : value;
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

  Future<void> _openFindMosque() async {
    await Navigator.of(context).pushNamed(RouteNames.findMosque);
    if (!mounted) return;
    await _loadNearbyMosquePreview();
  }

  Future<void> _loadNearbyMosquePreview() async {
    final cached = await _mosqueResultsCacheService.load();
    if (!mounted) return;

    if (cached == null || cached.items.isEmpty) {
      _safeSetState(() {
        _nearbyMosquePreview = const [];
        _nearbyMosquePreviewUpdatedAt = null;
      });
      return;
    }

    final topItems = [...cached.items]
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    _safeSetState(() {
      _nearbyMosquePreview = topItems.take(3).toList(growable: false);
      _nearbyMosquePreviewUpdatedAt = cached.updatedAt;
    });
  }

  Future<void> _scheduleMealNotification({
    required int id,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!localNotificationsInitialized) return;
    _ensureTimezoneInitializedForScheduling();
    var scheduled = tz.TZDateTime.from(at, tz.local);
    final nowTz = tz.TZDateTime.now(tz.local);
    if (scheduled.isBefore(nowTz)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final tone = alertToneNotifier.value;
    NotificationDetails detailsForTone(AppAlertTone value) {
      final valuePlaySound = alertTonePlaySound(value);
      return NotificationDetails(
        android: AndroidNotificationDetails(
          channelIdForTone(channelId, tone: value),
          channelName,
          channelDescription: '$channelDescription (${alertToneLabel(value)})',
          importance: Importance.max,
          priority: Priority.high,
          playSound: valuePlaySound,
          sound: alertToneSound(value),
          audioAttributesUsage: alertToneUsage(value),
        ),
        iOS: DarwinNotificationDetails(presentSound: valuePlaySound),
      );
    }

    Future<void> scheduleWithDetails(
      NotificationDetails details, {
      required AndroidScheduleMode mode,
    }) async {
      await localNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: mode,
        payload: payload,
      );
    }

    final details = detailsForTone(tone);

    try {
      await scheduleWithDetails(
        details,
        mode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      // Android 13/14 may block exact alarms unless special permission is granted.
      if (e.code == 'exact_alarms_not_permitted') {
        await scheduleWithDetails(
          details,
          mode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else if (tone == AppAlertTone.adhan) {
        // If raw adhan sound is missing/invalid, fallback to default tone.
        final fallback = detailsForTone(AppAlertTone.appDefault);
        try {
          await scheduleWithDetails(
            fallback,
            mode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } on PlatformException catch (fallbackError) {
          if (fallbackError.code == 'exact_alarms_not_permitted') {
            await scheduleWithDetails(
              fallback,
              mode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          } else {
            rethrow;
          }
        }
      } else {
        rethrow;
      }
    }
  }

  void _ensureTimezoneInitializedForScheduling() {
    try {
      // Accessing tz.local throws if local location was never configured.
      tz.local;
    } catch (_) {
      try {
        tz_data.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {
        // Keep scheduling flow from crashing even in test environments.
      }
    }
  }

  Future<void> _scheduleSehriNotification(DateTime sehriTime) async {
    if (!sehriAlertEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: sehriNotificationId,
      channelId: 'sehri_alert_channel',
      channelName: 'Sehri Alerts',
      channelDescription: 'Alert when Sehri time starts',
      at: sehriTime,
      title: _localizedSehriAlertTitle(),
      body: _localizedSehriAlertBody(),
      payload: 'sehri',
    );
  }

  Future<void> _schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime at,
  }) async {
    if (!prayerAlertsEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: id,
      channelId: 'prayer_alert_channel',
      channelName: 'Prayer Alerts',
      channelDescription: 'Alert when prayer time starts',
      at: at,
      title: '$prayerName Prayer Alert',
      body: 'It is time for $prayerName prayer.',
      payload: 'prayer_${prayerName.toLowerCase()}',
    );
  }

  Future<void> _cancelPrayerNotifications() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(fajrNotificationId);
    await localNotificationsPlugin.cancel(dzuhrNotificationId);
    await localNotificationsPlugin.cancel(ashrNotificationId);
    await localNotificationsPlugin.cancel(maghribNotificationId);
    await localNotificationsPlugin.cancel(ishaNotificationId);
  }

  Future<void> _refreshPrayerAlertScheduling() async {
    try {
      if (!prayerAlertsEnabledNotifier.value) {
        await _cancelPrayerNotifications();
        return;
      }

      final schedule = _todaySchedule;
      if (schedule == null) return;

      await _schedulePrayerNotification(
        id: fajrNotificationId,
        prayerName: 'Fajr',
        at: schedule.fajr,
      );
      await _schedulePrayerNotification(
        id: dzuhrNotificationId,
        prayerName: 'Zuhr',
        at: schedule.dzuhr,
      );
      await _schedulePrayerNotification(
        id: ashrNotificationId,
        prayerName: 'Asr',
        at: schedule.ashr,
      );
      await _schedulePrayerNotification(
        id: maghribNotificationId,
        prayerName: 'Maghrib',
        at: schedule.maghrib,
      );
      await _schedulePrayerNotification(
        id: ishaNotificationId,
        prayerName: 'Isha',
        at: schedule.isha,
      );
    } catch (e) {
      debugPrint('Prayer alert scheduling failed: $e');
    }
  }

  Future<void> _scheduleIftarNotification(DateTime iftarTime) async {
    if (!iftarAlertEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: iftarNotificationId,
      channelId: 'iftar_alert_channel',
      channelName: 'Iftar Alerts',
      channelDescription: 'Alert when Iftar time starts',
      at: iftarTime,
      title: _localizedIftarAlertTitle(),
      body: _localizedIftarAlertBody(),
      payload: 'iftar',
    );
  }

  Future<void> _cancelSehriNotification() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(sehriNotificationId);
  }

  Future<void> _cancelIftarNotification() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(iftarNotificationId);
  }

  Future<void> _refreshMealAlertScheduling() async {
    try {
      if (_nextSehriAt != null) {
        if (sehriAlertEnabledNotifier.value) {
          await _scheduleSehriNotification(_nextSehriAt!);
        } else {
          await _cancelSehriNotification();
        }
      }

      if (_nextIftarAt != null) {
        if (iftarAlertEnabledNotifier.value) {
          await _scheduleIftarNotification(_nextIftarAt!);
        } else {
          await _cancelIftarNotification();
        }
      }
    } catch (e) {
      debugPrint('Meal alert scheduling failed: $e');
    }
  }

  Future<void> _scheduleTahajjudNotification(DateTime tahajjudTime) async {
    if (!tahajjudAlertEnabledNotifier.value) return;
    await _scheduleMealNotification(
      id: tahajjudNotificationId,
      channelId: 'tahajjud_alert_channel',
      channelName: 'Tahajjud Reminders',
      channelDescription: 'Reminder for the last third of the night',
      at: tahajjudTime,
      title: _localizedTahajjudAlertTitle(),
      body: _localizedTahajjudAlertBody(),
      payload: 'tahajjud',
    );
  }

  Future<void> _cancelTahajjudNotification() async {
    if (!localNotificationsInitialized) return;
    await localNotificationsPlugin.cancel(tahajjudNotificationId);
  }

  Future<void> _refreshTahajjudAlertScheduling() async {
    try {
      final at = _nextTahajjudTimeForSchedule();
      if (at == null) return;
      if (tahajjudAlertEnabledNotifier.value) {
        await _scheduleTahajjudNotification(at);
      } else {
        await _cancelTahajjudNotification();
      }
    } catch (e) {
      debugPrint('Tahajjud alert scheduling failed: $e');
    }
  }

  String get _displayPrayer => _selectedPrayer ?? _activePrayer;
  bool get _isShowingActivePrayer => _displayPrayer == _activePrayer;

  int get _prayerCarouselItemsCount => _prayerCarouselItemCount;

  String _prayerForCarouselIndex(int index) {
    final len = _prayerOrder.length;
    final normalized = ((index % len) + len) % len;
    return _prayerOrder[normalized];
  }

  int _carouselIndexForPrayer(String prayer, {int? around}) {
    final prayerIndex = _prayerOrder.indexOf(prayer);
    if (prayerIndex == -1) {
      return _prayerCarouselSeed * _prayerOrder.length;
    }

    final len = _prayerOrder.length;
    if (around == null) {
      return (_prayerCarouselSeed * len) + prayerIndex;
    }

    final base = around - (around % len);
    final candidates = <int>[
      base + prayerIndex,
      base + prayerIndex + len,
      base + prayerIndex - len,
    ];
    candidates.sort((a, b) => (a - around).abs().compareTo((b - around).abs()));
    return candidates.first;
  }

  int _currentCarouselPage() {
    if (_prayerPageController.hasClients) {
      return _prayerPageController.page?.round() ??
          _prayerPageController.initialPage;
    }
    return _prayerPageController.initialPage;
  }

  void _syncPrayerPageToActive({required bool animate}) {
    if (!_prayerPageController.hasClients) return;
    final target = _carouselIndexForPrayer(
      _activePrayer,
      around: _currentCarouselPage(),
    );
    if (animate) {
      _prayerPageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _prayerPageController.jumpToPage(target);
    }
  }

  Future<void> _loadPrayerData() async {
    if (!useDeviceLocationNotifier.value) {
      _setBaitulMukarramLocation();
      await _refreshPrayerScheduleFromSource(forceRefresh: true);
      return;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setUseDeviceLocationSilently(false);
        _setBaitulMukarramLocation();
        await _refreshPrayerScheduleFromSource(forceRefresh: true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (locationPermissionRequestInProgress) {
          _setBaitulMukarramLocation();
          await _refreshPrayerScheduleFromSource(forceRefresh: true);
          return;
        }
        locationPermissionRequestInProgress = true;
        try {
          permission = await Geolocator.requestPermission();
        } finally {
          locationPermissionRequestInProgress = false;
        }
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setUseDeviceLocationSilently(false);
        _setBaitulMukarramLocation();
        await _refreshPrayerScheduleFromSource(forceRefresh: true);
        return;
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 8));
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown == null) rethrow;
        position = lastKnown;
      }
      _latitude = position.latitude;
      _longitude = position.longitude;
      _updateHomeQiblaBearing(position.latitude, position.longitude);
      await _resolveLocationLabel(position.latitude, position.longitude);
    } catch (e) {
      _setBaitulMukarramLocation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not read current location. Using fallback temporarily.',
            ),
          ),
        );
      }
      debugPrint('Device location fetch failed: $e');
    }

    await _refreshPrayerScheduleFromSource(forceRefresh: true);
  }

  void _setBaitulMukarramLocation() {
    _latitude = _baitulMukarramLat;
    _longitude = _baitulMukarramLng;
    _updateHomeQiblaBearing(_baitulMukarramLat, _baitulMukarramLng);
    _safeSetState(() => _locationLabel = _profileOrFallbackLocationLabel());
  }

  String _profileOrFallbackLocationLabel() {
    final profileLocation = profileLocationNotifier.value.trim();
    if (profileLocation.isNotEmpty) return profileLocation;
    return _baitulMukarramLabel;
  }

  Future<void> _resolveLocationLabel(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty || !mounted) return;
      final place = placemarks.first;
      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea ??
          'Current location';
      final area = place.administrativeArea ?? place.country ?? '';
      final label = area.isNotEmpty ? '$city, $area' : city;
      _safeSetState(() => _locationLabel = label);
      if (profileLocationNotifier.value != label) {
        profileLocationNotifier.value = label;
        await saveAppPreferences();
      }
    } catch (_) {
      _safeSetState(() => _locationLabel = 'Current location');
    }
  }

  Future<void> _refreshLocationFromHeader() async {
    if (_isRefreshingLocation) return;
    _isRefreshingLocation = true;
    try {
      _setUseDeviceLocationSilently(true);
      await _loadPrayerData();
      await saveAppPreferences();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prayer times updated for $_locationLabel')),
      );
    } finally {
      _isRefreshingLocation = false;
    }
  }

  Future<void> _refreshPrayerScheduleFromSource({
    required bool forceRefresh,
  }) async {
    if (!mounted) return;
    if (_isFetchingPrayerSchedule) return;
    final today = DateTime(_now.year, _now.month, _now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final alreadyLoaded =
        _todaySchedule != null &&
        _tomorrowSchedule != null &&
        _isSameDate(_todaySchedule!.date, today) &&
        _isSameDate(_tomorrowSchedule!.date, tomorrow);
    if (!forceRefresh && alreadyLoaded) return;

    _isFetchingPrayerSchedule = true;
    try {
      final results = await Future.wait<DailyPrayerSchedule>([
        _fetchPrayerScheduleFromApi(today),
        _fetchPrayerScheduleFromApi(tomorrow),
      ]);
      _todaySchedule = results[0];
      _tomorrowSchedule = results[1];
    } catch (_) {
      // Fallback for offline mode or API failure.
      _todaySchedule = _buildFallbackSchedule(today);
      _tomorrowSchedule = _buildFallbackSchedule(tomorrow);
      if (mounted && forceRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using offline calculated prayer times'),
          ),
        );
      }
    } finally {
      _isFetchingPrayerSchedule = false;
    }

    if (!mounted) return;
    _recalculatePrayerTimesForToday();
  }

  Future<DailyPrayerSchedule> _fetchPrayerScheduleFromApi(DateTime date) async {
    final latitude = _latitude ?? _baitulMukarramLat;
    final longitude = _longitude ?? _baitulMukarramLng;
    final response = await _prayerApi.get(
      '/v1/timings/${_formatApiDate(date)}',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'method': _apiMethod,
        'school': _apiSchool,
      },
    );

    final root = response.data;
    if (root is! Map) {
      throw const FormatException('Invalid prayer response root');
    }
    final data = root['data'];
    if (data is! Map) {
      throw const FormatException('Invalid prayer response data');
    }
    final timings = data['timings'];
    if (timings is! Map) {
      throw const FormatException('Invalid prayer response timings');
    }

    String valueFor(String key) => (timings[key] ?? '').toString();
    return DailyPrayerSchedule(
      date: DateTime(date.year, date.month, date.day),
      imsak: _parseApiTime(date, valueFor('Imsak')),
      fajr: _parseApiTime(date, valueFor('Fajr')),
      sunrise: _parseApiTimeOrNull(date, valueFor('Sunrise')),
      dzuhr: _parseApiTime(date, valueFor('Dhuhr')),
      ashr: _parseApiTime(date, valueFor('Asr')),
      maghrib: _parseApiTime(date, valueFor('Maghrib')),
      isha: _parseApiTime(date, valueFor('Isha')),
    );
  }

  String _formatApiDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd-$mm-${date.year}';
  }

  DateTime _parseApiTime(DateTime date, String raw) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) {
      throw FormatException('Invalid prayer time: $raw');
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Lenient variant of [_parseApiTime] for optional timings (e.g. Sunrise):
  /// returns null instead of throwing when the value is missing or malformed.
  DateTime? _parseApiTimeOrNull(DateTime date, String raw) {
    try {
      return _parseApiTime(date, raw);
    } catch (_) {
      return null;
    }
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DailyPrayerSchedule _buildFallbackSchedule(DateTime date) {
    final prayers = _prayerTimesForDate(date);
    return DailyPrayerSchedule(
      date: DateTime(date.year, date.month, date.day),
      imsak: prayers.fajr.toLocal(),
      fajr: prayers.fajr.toLocal(),
      sunrise: prayers.sunrise.toLocal(),
      dzuhr: prayers.dhuhr.toLocal(),
      ashr: prayers.asr.toLocal(),
      maghrib: prayers.maghrib.toLocal(),
      isha: prayers.isha.toLocal(),
    );
  }

  CalculationParameters _buildCalculationParams() {
    final params = CalculationMethodParameters.karachi();
    params.madhab = Madhab.hanafi;
    return params;
  }

  PrayerTimes _prayerTimesForDate(DateTime date) {
    final latitude = _latitude ?? _baitulMukarramLat;
    final longitude = _longitude ?? _baitulMukarramLng;
    return PrayerTimes(
      date: date,
      coordinates: Coordinates(latitude, longitude),
      calculationParameters: _buildCalculationParams(),
    );
  }

  RamadanMealData _buildRamadanMealData({
    required DateTime now,
    required DateTime sehri,
    required DateTime maghrib,
    required DateTime tomorrowSehri,
    required DateTime tomorrowMaghrib,
  }) {
    final nextSehri = now.isBefore(sehri) ? sehri : tomorrowSehri;
    final nextIftar = now.isBefore(maghrib) ? maghrib : tomorrowMaghrib;
    return RamadanMealData(nextSehri: nextSehri, nextIftar: nextIftar);
  }

  void _recalculatePrayerTimesForToday() {
    if (!mounted) return;
    final today = DateTime(_now.year, _now.month, _now.day);

    final scheduleToday = _todaySchedule;
    final scheduleTomorrow = _tomorrowSchedule;
    if (scheduleToday == null ||
        scheduleTomorrow == null ||
        !_isSameDate(scheduleToday.date, today)) {
      unawaited(_refreshPrayerScheduleFromSource(forceRefresh: true));
      return;
    }

    final fajr = scheduleToday.fajr;
    final dzuhr = scheduleToday.dzuhr;
    final ashr = scheduleToday.ashr;
    final maghrib = scheduleToday.maghrib;
    final isha = scheduleToday.isha;
    final ishaBefore = scheduleToday.isha.subtract(const Duration(days: 1));
    final mealData = _buildRamadanMealData(
      now: _now,
      sehri: scheduleToday.imsak,
      maghrib: maghrib,
      tomorrowSehri: scheduleTomorrow.imsak,
      tomorrowMaghrib: scheduleTomorrow.maghrib,
    );
    final activeData = _buildActivePrayerData(
      now: _now,
      fajr: fajr,
      dzuhr: dzuhr,
      ashr: ashr,
      maghrib: maghrib,
      isha: isha,
      ishaBefore: ishaBefore,
    );

    _safeSetState(() {
      _lastPrayerCalcDate = today;
      _prayerTimes = {
        'Fajr': _formatPrayerTime(fajr),
        'Zuhr': _formatPrayerTime(dzuhr),
        'Asr': _formatPrayerTime(ashr),
        'Maghrib': _formatPrayerTime(maghrib),
        'Isha': _formatPrayerTime(isha),
      };
      _activePrayer = activeData.name;
      _countdownLabel = activeData.countdownLabel;
      _activeRemaining = activeData.remaining;
      _activeProgress = activeData.progress;
      _nextSehriAt = mealData.nextSehri;
      _nextIftarAt = mealData.nextIftar;
    });
    _refreshMealAlertScheduling();
    _refreshPrayerAlertScheduling();
    _refreshTahajjudAlertScheduling();
    if (_selectedPrayer == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncPrayerPageToActive(animate: false);
      });
    }
  }

  void _updateCountdown() {
    if (_prayerTimes['Fajr'] == '--:--') return;
    final today = DateTime(_now.year, _now.month, _now.day);
    final scheduleToday = _todaySchedule;
    final scheduleTomorrow = _tomorrowSchedule;
    if (scheduleToday == null ||
        scheduleTomorrow == null ||
        !_isSameDate(scheduleToday.date, today)) {
      if (!_isFetchingPrayerSchedule) {
        unawaited(_refreshPrayerScheduleFromSource(forceRefresh: true));
      }
      return;
    }

    final fajr = scheduleToday.fajr;
    final dzuhr = scheduleToday.dzuhr;
    final ashr = scheduleToday.ashr;
    final maghrib = scheduleToday.maghrib;
    final isha = scheduleToday.isha;
    final ishaBefore = scheduleToday.isha.subtract(const Duration(days: 1));
    final mealData = _buildRamadanMealData(
      now: _now,
      sehri: scheduleToday.imsak,
      maghrib: maghrib,
      tomorrowSehri: scheduleTomorrow.imsak,
      tomorrowMaghrib: scheduleTomorrow.maghrib,
    );
    final activeData = _buildActivePrayerData(
      now: _now,
      fajr: fajr,
      dzuhr: dzuhr,
      ashr: ashr,
      maghrib: maghrib,
      isha: isha,
      ishaBefore: ishaBefore,
    );
    final mealsChanged =
        mealData.nextSehri != _nextSehriAt ||
        mealData.nextIftar != _nextIftarAt;

    if (mounted &&
        (activeData.name != _activePrayer ||
            activeData.countdownLabel != _countdownLabel ||
            activeData.progress != _activeProgress ||
            activeData.remaining != _activeRemaining ||
            mealsChanged)) {
      _safeSetState(() {
        _activePrayer = activeData.name;
        _countdownLabel = activeData.countdownLabel;
        _activeRemaining = activeData.remaining;
        _activeProgress = activeData.progress;
        _nextSehriAt = mealData.nextSehri;
        _nextIftarAt = mealData.nextIftar;
      });
      if (mealsChanged) {
        _refreshMealAlertScheduling();
      }
      if (_selectedPrayer == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncPrayerPageToActive(animate: true);
        });
      }
    }
  }

  String _formatPrayerTime(DateTime time) {
    final h = (time.hour % 12 == 0 ? 12 : time.hour % 12).toString();
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  ActivePrayerData _buildActivePrayerData({
    required DateTime now,
    required DateTime fajr,
    required DateTime dzuhr,
    required DateTime ashr,
    required DateTime maghrib,
    required DateTime isha,
    required DateTime ishaBefore,
  }) {
    final schedule = <MapEntry<String, DateTime>>[
      MapEntry('Fajr', fajr),
      MapEntry('Zuhr', dzuhr),
      MapEntry('Asr', ashr),
      MapEntry('Maghrib', maghrib),
      MapEntry('Isha', isha),
    ];

    // The "active" prayer is the one currently in progress: the most recent
    // prayer whose time has already begun. The next prayer's time marks when
    // the current window closes, which drives the countdown and progress bar.
    MapEntry<String, DateTime> currentPrayer;
    DateTime windowEnd;
    if (now.isBefore(fajr)) {
      // After midnight but before dawn: last night's Isha is still ongoing.
      currentPrayer = MapEntry('Isha', ishaBefore);
      windowEnd = fajr;
    } else {
      int currentIndex = 0;
      for (int i = 0; i < schedule.length; i++) {
        if (schedule[i].value.isAfter(now)) break;
        currentIndex = i;
      }
      currentPrayer = schedule[currentIndex];
      windowEnd = currentIndex + 1 < schedule.length
          ? schedule[currentIndex + 1].value
          : fajr.add(const Duration(days: 1));
    }

    final remaining = windowEnd.difference(now);
    final totalWindow = windowEnd.difference(currentPrayer.value);
    final elapsed = totalWindow - remaining;
    final progress = totalWindow.inMilliseconds <= 0
        ? 0.0
        : (elapsed.inMilliseconds / totalWindow.inMilliseconds).clamp(0.0, 1.0);
    final hh = remaining.inHours.toString().padLeft(2, '0');
    final mm = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return ActivePrayerData(
      name: currentPrayer.key,
      countdownLabel: '${currentPrayer.key} in $hh:$mm:$ss',
      remaining: remaining.isNegative ? Duration.zero : remaining,
      progress: progress,
    );
  }

  String _formattedActiveRemaining() {
    final d = _activeRemaining.isNegative ? Duration.zero : _activeRemaining;
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    final value = '$hh:$mm:$ss';
    return _isBangla ? _toBanglaDigits(value) : value;
  }
}
