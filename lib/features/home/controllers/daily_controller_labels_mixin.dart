part of '../screens/daily_activity_screen.dart';

mixin DailyControllerLabelsMixin on State<DailyActivityScreen>, DailyControllerFormatMixin {
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
      ? '\u0985\u09ac\u09b6\u09bf\u09b7\u09cd\u099f'
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

  String _formattedActiveRemaining() {
    final d = _activeRemaining.isNegative ? Duration.zero : _activeRemaining;
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    final value = '$hh:$mm:$ss';
    return _isBangla ? _toBanglaDigits(value) : value;
  }

}
