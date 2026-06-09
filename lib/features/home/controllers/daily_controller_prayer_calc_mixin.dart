part of '../screens/daily_activity_screen.dart';

mixin DailyControllerPrayerCalcMixin on State<DailyActivityScreen>, DailyControllerLabelsMixin {
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

  /// True during the post-sunrise gap: Fajr's window has already closed at
  /// sunrise but Zuhr has not begun, so no fard prayer is in progress. (The sky
  /// section still treats this stretch as Fajr→Chasht, so [_activePrayer] is
  /// intentionally left as 'Fajr' here.)
  bool get _isPostSunriseGap {
    final sunrise = _todaySchedule?.sunrise;
    if (sunrise == null) return false;
    return _activePrayer == 'Fajr' && !_now.isBefore(sunrise);
  }

  /// The prayer whose window is actually in progress right now, or null during
  /// the post-sunrise gap when no obligatory prayer is active.
  String? get _currentActivePrayer => _isPostSunriseGap ? null : _activePrayer;

  /// The prayer whose card should be highlighted: the user's manual selection,
  /// otherwise the prayer currently in progress. Null when nothing should be
  /// highlighted — i.e. no manual selection during the post-sunrise gap.
  String? get _displayPrayer => _selectedPrayer ?? _currentActivePrayer;

  /// Whether the strip is tracking the live prayer: no manual selection and a
  /// prayer is genuinely in progress (not the post-sunrise gap).
  bool get _isShowingActivePrayer =>
      _selectedPrayer == null && !_isPostSunriseGap;

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

}
