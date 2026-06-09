part of '../../screens/profile_preferences_screen.dart';

/// Lower rows of the 'Prayer Setting' card (translator, reciter, alerts).
mixin ProfilePrefsPrayerSectionBMixin
    on
        State<ProfilePreferencesScreen>,
        ProfilePrefsStateMixin,
        ProfilePrefsUiMixin,
        ProfilePrefsSettingsMixin,
        ProfilePrefsPickersMixin {
  List<Widget> _prayerRowsBottom(NoorifyGlassTheme glass) {
    return [
      Divider(height: 1, color: glass.glassBorder),
      ValueListenableBuilder<String>(
        valueListenable: translatorNotifier,
        builder: (context, translator, _) {
          return _rowTile(
            icon: Icons.person_outline,
            title: _text(
              'Translator',
              '\u0985\u09a8\u09c1\u09ac\u09be\u09a6\u0995',
            ),
            subtitle: translator,
            onTap: () async {
              final selected = await _pickOption(
                title: _text(
                  'Translator',
                  '\u0985\u09a8\u09c1\u09ac\u09be\u09a6\u0995',
                ),
                options: const [
                  'Dr. Mustafa Khattab',
                  'Muhiuddin Khan',
                  'Tafsir Ibn Kathir (Brief)',
                ],
                current: translator,
              );
              if (selected == null || selected == translator) {
                return;
              }
              translatorNotifier.value = selected;
              await saveAppPreferences();
            },
          );
        },
      ),
      Divider(height: 1, color: glass.glassBorder),
      ValueListenableBuilder<String>(
        valueListenable: reciterNotifier,
        builder: (context, reciter, _) {
          return _rowTile(
            icon: Icons.mic_none_rounded,
            title: _text('Reciters', '\u0995\u09be\u09b0\u09c0'),
            subtitle: reciter,
            onTap: () async {
              final selected = await _pickOption(
                title: _text('Reciter', '\u0995\u09be\u09b0\u09c0'),
                options: const [
                  'Mishary Rashid Alafasy',
                  'Saad Al-Ghamdi',
                  'Maher Al Muaiqly',
                ],
                current: reciter,
              );
              if (selected == null || selected == reciter) {
                return;
              }
              reciterNotifier.value = selected;
              await saveAppPreferences();
            },
          );
        },
      ),
      Divider(height: 1, color: glass.glassBorder),
      ValueListenableBuilder2<bool, String>(
        first: prayerAlertsEnabledNotifier,
        second: adzanVoiceNotifier,
        builder: (context, enabled, voice, _) {
          return _switchRow(
            icon: Icons.notifications_active_outlined,
            title: _text(
              'Adzan Notification',
              '\u0986\u09af\u09be\u09a8 \u09a8\u09cb\u099f\u09bf\u09ab\u09bf\u0995\u09c7\u09b6\u09a8',
            ),
            subtitle: voice,
            value: enabled,
            onChanged: (value) async {
              await _setAdzanNotification(value);
              if (!value) return;
              final selected = await _pickOption(
                title: _text(
                  'Adzan Voice',
                  '\u0986\u09af\u09be\u09a8\u09c7\u09b0 \u09ad\u09df\u09c7\u09b8',
                ),
                options: const [
                  'Hanan Attaki',
                  'Mishary Alafasy',
                  'Maher Al Muaiqly',
                ],
                current: voice,
              );
              if (selected == null || selected == voice) {
                return;
              }
              adzanVoiceNotifier.value = selected;
              await saveAppPreferences();
            },
          );
        },
      ),
      Divider(height: 1, color: glass.glassBorder),
      ValueListenableBuilder2<bool, String>(
        first: sehriAlertEnabledNotifier,
        second: imsakVoiceNotifier,
        builder: (context, enabled, voice, _) {
          return _switchRow(
            icon: Icons.alarm_on_outlined,
            title: _text(
              'Imsak Notification',
              '\u0987\u09ae\u09b8\u09be\u0995 \u09a8\u09cb\u099f\u09bf\u09ab\u09bf\u0995\u09c7\u09b6\u09a8',
            ),
            subtitle: voice,
            value: enabled,
            onChanged: (value) async {
              await _setImsakNotification(value);
              if (!value) return;
              final selected = await _pickOption(
                title: _text(
                  'Imsak Tone',
                  '\u0987\u09ae\u09b8\u09be\u0995 \u099f\u09cb\u09a8',
                ),
                options: const ['Default', 'Gentle', 'Beep'],
                current: voice,
              );
              if (selected == null || selected == voice) {
                return;
              }
              imsakVoiceNotifier.value = selected;
              await saveAppPreferences();
            },
          );
        },
      ),
    ];
  }
}
