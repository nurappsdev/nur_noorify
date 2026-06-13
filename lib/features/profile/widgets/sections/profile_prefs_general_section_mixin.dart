part of '../../screens/profile_preferences_screen.dart';

/// 'General' settings card: font size, language, password, theme, etc.
mixin ProfilePrefsGeneralSectionMixin
    on
        State<ProfilePreferencesScreen>,
        ProfilePrefsStateMixin,
        ProfilePrefsUiMixin,
        ProfilePrefsSettingsMixin,
        ProfilePrefsPickersMixin,
        ProfilePrefsAccountMixin {
  List<Widget> _buildGeneralSection() {
    final glass = NoorifyGlassTheme(context);
    return [
      _sectionLabel(_text('General', '\u09b8\u09be\u09a7\u09be\u09b0\u09a3')),
      _sectionCard(
        child: Column(
          children: [
            ValueListenableBuilder<AppFontSize>(
              valueListenable: appFontSizeNotifier,
              builder: (context, size, _) {
                return _rowTile(
                  icon: Icons.text_fields_rounded,
                  title: _text(
                    'Font Size',
                    '\u09ab\u09a8\u09cd\u099f \u09b8\u09be\u0987\u099c',
                  ),
                  subtitle: _fontSizeLabel(size),
                  onTap: _selectFontSize,
                );
              },
            ),
            Divider(height: 1, color: glass.glassBorder),
            ValueListenableBuilder<AppLanguage>(
              valueListenable: appLanguageNotifier,
              builder: (context, language, _) {
                final isBangla = language == AppLanguage.bangla;
                return _switchRow(
                  icon: Icons.language_rounded,
                  title: _text(
                    'Language Select',
                    '\u09ad\u09be\u09b7\u09be \u09a8\u09bf\u09b0\u09cd\u09ac\u09be\u099a\u09a8',
                  ),
                  subtitle: _text(
                    isBangla ? 'Current: Bangla' : 'Current: English',
                    isBangla
                        ? '\u09ac\u09b0\u09cd\u09a4\u09ae\u09be\u09a8: \u09ac\u09be\u0982\u09b2\u09be'
                        : '\u09ac\u09b0\u09cd\u09a4\u09ae\u09be\u09a8: \u0987\u0982\u09b0\u09c7\u099c\u09bf',
                  ),
                  value: isBangla,
                  onChanged: (value) {
                    _setAppLanguage(
                      value ? AppLanguage.bangla : AppLanguage.english,
                    );
                  },
                  onTap: () {},
                );
              },
            ),
            Divider(height: 1, color: glass.glassBorder),
            _rowTile(
              icon: Icons.lock_outline_rounded,
              title: _text(
                'Change Password',
                '\u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09aa\u09b0\u09bf\u09ac\u09b0\u09cd\u09a4\u09a8',
              ),
              subtitle: _text(
                'Update your account password',
                '\u0986\u09aa\u09a8\u09be\u09b0 \u0985\u09cd\u09af\u09be\u0995\u09be\u0989\u09a8\u09cd\u099f\u09c7\u09b0 \u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u0986\u09aa\u09a1\u09c7\u099f \u0995\u09b0\u09c1\u09a8',
              ),
              onTap: _openChangePassword,
            ),
            Divider(height: 1, color: glass.glassBorder),
            ValueListenableBuilder<bool>(
              valueListenable: darkThemeEnabledNotifier,
              builder: (context, enabled, _) {
                return _switchRow(
                  icon: Icons.dark_mode_outlined,
                  title: _text(
                    'Dark Theme',
                    '\u09a1\u09be\u09b0\u09cd\u0995 \u09a5\u09bf\u09ae',
                  ),
                  subtitle: _text(
                    'Switch to dark color scheme',
                    '\u09a1\u09be\u09b0\u09cd\u0995 \u0995\u09be\u09b2\u09be\u09b0 \u09b8\u09cd\u0995\u09bf\u09ae \u099a\u09be\u09b2\u09c1 \u0995\u09b0\u09c1\u09a8',
                  ),
                  value: enabled,
                  onChanged: _setDarkTheme,
                );
              },
            ),
            Divider(height: 1, color: glass.glassBorder),
            ValueListenableBuilder<bool>(
              valueListenable: hapticFeedbackEnabledNotifier,
              builder: (context, enabled, _) {
                return _switchRow(
                  icon: Icons.vibration_rounded,
                  title: _text(
                    'Vibration',
                    '\u09ad\u09be\u0987\u09ac\u09cd\u09b0\u09c7\u09b6\u09a8',
                  ),
                  subtitle: _text(
                    'Enable vibration feedback in app actions',
                    '\u0985\u09cd\u09af\u09be\u09aa\u09c7\u09b0 \u0995\u09be\u099c\u0997\u09c1\u09b2\u09cb\u09a4\u09c7 \u09ad\u09be\u0987\u09ac\u09cd\u09b0\u09c7\u09b6\u09a8 \u09ab\u09bf\u09a1\u09ac\u09cd\u09af\u09be\u0995 \u099a\u09be\u09b2\u09c1 \u0995\u09b0\u09c1\u09a8',
                  ),
                  value: enabled,
                  onChanged: _setHapticFeedback,
                );
              },
            ),
            Divider(height: 1, color: glass.glassBorder),
            ValueListenableBuilder<bool>(
              valueListenable: useDeviceLocationNotifier,
              builder: (context, enabled, _) {
                return _switchRow(
                  icon: Icons.my_location_rounded,
                  title: _text(
                    'Use Device Location',
                    '\u09a1\u09bf\u09ad\u09be\u0987\u09b8 \u09b2\u09cb\u0995\u09c7\u09b6\u09a8 \u09ac\u09cd\u09af\u09ac\u09b9\u09be\u09b0',
                  ),
                  subtitle: _text(
                    'Accurate prayer/sehri/iftar by your area',
                    '\u0986\u09aa\u09a8\u09be\u09b0 \u098f\u09b2\u09be\u0995\u09be\u09b0 \u09b8\u09a0\u09bf\u0995 \u09b8\u09be\u09b2\u09be\u09a4/\u09b8\u09c7\u09b9\u09b0\u09bf/\u0987\u09ab\u09a4\u09be\u09b0 \u09b8\u09ae\u09df',
                  ),
                  value: enabled,
                  onChanged: _setUseDeviceLocation,
                );
              },
            ),
          ],
        ),
      ),
    ];
  }
}
