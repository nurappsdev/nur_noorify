part of '../screens/daily_activity_screen.dart';

mixin DailyControllerPrayerDataMixin on State<DailyActivityScreen>, DailyControllerAlertsMixin {
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

}
