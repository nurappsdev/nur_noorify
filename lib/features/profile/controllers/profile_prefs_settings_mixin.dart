part of '../screens/profile_preferences_screen.dart';

/// Preference toggle/setter actions that persist app settings.
mixin ProfilePrefsSettingsMixin
    on State<ProfilePreferencesScreen>, ProfilePrefsStateMixin {
  Future<void> _setFontSize(AppFontSize value) async {
    appFontSizeNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setAppLanguage(AppLanguage language) async {
    if (appLanguageNotifier.value == language) return;
    appLanguageNotifier.value = language;
    await saveAppPreferences();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          language == AppLanguage.bangla
              ? '\u0985\u09cd\u09af\u09be\u09aa \u09ad\u09be\u09b7\u09be \u09ac\u09be\u0982\u09b2\u09be \u0995\u09b0\u09be \u09b9\u09df\u09c7\u099b\u09c7'
              : 'App language switched to English',
        ),
      ),
    );
  }

  Future<void> _setDarkTheme(bool value) async {
    darkThemeEnabledNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setHapticFeedback(bool value) async {
    hapticFeedbackEnabledNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setUseDeviceLocation(bool value) async {
    try {
      if (!value) {
        useDeviceLocationNotifier.value = false;
        await saveAppPreferences();
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        useDeviceLocationNotifier.value = false;
        await saveAppPreferences();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Please enable phone location service first',
                '\u09aa\u09cd\u09b0\u09a5\u09ae\u09c7 \u09ab\u09cb\u09a8\u09c7\u09b0 \u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09b8\u09be\u09b0\u09cd\u09ad\u09bf\u09b8 \u099a\u09be\u09b2\u09c1 \u0995\u09b0\u09c1\u09a8',
              ),
            ),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        useDeviceLocationNotifier.value = false;
        await saveAppPreferences();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Location permission is permanently denied. Enable it in app settings.',
                '\u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09aa\u09be\u09b0\u09ae\u09bf\u09b6\u09a8 \u09b8\u09cd\u09a5\u09be\u09df\u09c0\u09ad\u09be\u09ac\u09c7 \u09ac\u09a8\u09cd\u09a7\u0964 \u0985\u09cd\u09af\u09be\u09aa \u09b8\u09c7\u099f\u09bf\u0982\u09b8 \u09a5\u09c7\u0995\u09c7 \u099a\u09be\u09b2\u09c1 \u0995\u09b0\u09c1\u09a8\u0964',
              ),
            ),
          ),
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        useDeviceLocationNotifier.value = false;
        await saveAppPreferences();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Location permission is needed for accurate timings',
                '\u09b8\u09a0\u09bf\u0995 \u09b8\u09ae\u09df\u09c7\u09b0 \u099c\u09a8\u09cd\u09af \u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09aa\u09be\u09b0\u09ae\u09bf\u09b6\u09a8 \u09aa\u09cd\u09b0\u09df\u09cb\u099c\u09a8',
              ),
            ),
          ),
        );
        return;
      }

      useDeviceLocationNotifier.value = value;
      await saveAppPreferences();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Device location enabled',
              '\u09a1\u09bf\u09ad\u09be\u0987\u09b8 \u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u099a\u09be\u09b2\u09c1 \u09b9\u09df\u09c7\u099b\u09c7',
            ),
          ),
        ),
      );
    } catch (e) {
      useDeviceLocationNotifier.value = false;
      await saveAppPreferences();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Unable to enable location on this device right now',
              '\u098f\u0987 \u09a1\u09bf\u09ad\u09be\u0987\u09b8\u09c7 \u098f\u0996\u09a8 \u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u099a\u09be\u09b2\u09c1 \u0995\u09b0\u09be \u09af\u09be\u099a\u09cd\u099b\u09c7 \u09a8\u09be',
            ),
          ),
        ),
      );
      debugPrint('Use device location toggle failed: $e');
    }
  }

  Future<void> _setShowLatinLetters(bool value) async {
    showLatinLettersNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setShowTranslation(bool value) async {
    showTranslationNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setShowTajweed(bool value) async {
    showTajweedNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setAdzanNotification(bool value) async {
    prayerAlertsEnabledNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setImsakNotification(bool value) async {
    sehriAlertEnabledNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _setHifzMode(bool value) async {
    hifzModeEnabledNotifier.value = value;
    if (!value) {
      hifzHideBanglaMeaningNotifier.value = false;
    }
    await saveAppPreferences();
  }

  Future<void> _setHifzHideBanglaMeaning(bool value) async {
    hifzHideBanglaMeaningNotifier.value = value;
    await saveAppPreferences();
  }
}
