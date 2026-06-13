part of '../screens/daily_activity_screen.dart';

mixin DailyControllerScheduleDataMixin on State<DailyActivityScreen>, DailyControllerPrayerCalcMixin {
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

}
