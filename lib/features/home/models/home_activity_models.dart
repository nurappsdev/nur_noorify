class ActivityItem {
  ActivityItem({required this.title, required this.done, required this.total});

  final String title;
  int done;
  final int total;
}

class DailyPrayerSchedule {
  const DailyPrayerSchedule({
    required this.date,
    required this.imsak,
    required this.fajr,
    required this.dzuhr,
    required this.ashr,
    required this.maghrib,
    required this.isha,
    this.sunrise,
  });

  final DateTime date;
  final DateTime imsak;
  final DateTime fajr;
  /// Actual sunrise (shuruq) — distinct from Fajr/dawn. Used by the forbidden
  /// prayer-times card; may be null for schedules built before it was tracked.
  final DateTime? sunrise;
  final DateTime dzuhr;
  final DateTime ashr;
  final DateTime maghrib;
  final DateTime isha;
}

class RamadanMealData {
  const RamadanMealData({required this.nextSehri, required this.nextIftar});

  final DateTime nextSehri;
  final DateTime nextIftar;
}

class ActivePrayerData {
  const ActivePrayerData({
    required this.name,
    required this.countdownLabel,
    required this.remaining,
    required this.progress,
  });

  final String name;
  final String countdownLabel;
  final Duration remaining;
  final double progress;
}
