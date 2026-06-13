part of '../screens/daily_activity_screen.dart';

mixin DailyControllerUtilsMixin on State<DailyActivityScreen>, DailyControllerStateMixin {
  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
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

  String _formatPrayerTime(DateTime time) {
    final h = (time.hour % 12 == 0 ? 12 : time.hour % 12).toString();
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

}
