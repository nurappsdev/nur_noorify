part of '../screens/daily_activity_screen.dart';

mixin DailyActivityControllerMixin on State<DailyActivityScreen>, DailyControllerAnnouncementsMixin {
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

}
