part of '../../screens/profile_preferences_screen.dart';

/// 'Prayer Setting' card scaffold and its upper rows.
mixin ProfilePrefsPrayerSectionAMixin
    on
        State<ProfilePreferencesScreen>,
        ProfilePrefsStateMixin,
        ProfilePrefsUiMixin,
        ProfilePrefsSettingsMixin,
        ProfilePrefsPickersMixin,
        ProfilePrefsPrayerSectionBMixin {
  List<Widget> _buildPrayerSettingSection() {
    final glass = NoorifyGlassTheme(context);
    return [
      _sectionLabel(
        _text(
          'Prayer Setting',
          '\u09aa\u09cd\u09b0\u09be\u09b0\u09cd\u09a5\u09a8\u09be \u09b8\u09c7\u099f\u09bf\u0982',
        ),
      ),
      _sectionCard(
        child: Column(
          children: [..._prayerRowsTop(glass), ..._prayerRowsBottom(glass)],
        ),
      ),
    ];
  }

  List<Widget> _prayerRowsTop(NoorifyGlassTheme glass) {
    return [
      ValueListenableBuilder<bool>(
        valueListenable: showLatinLettersNotifier,
        builder: (context, enabled, _) {
          return _switchRow(
            icon: Icons.short_text_rounded,
            title: _text(
              'Show English Transliteration',
              '\u0987\u0982\u09b0\u09c7\u099c\u09bf \u0989\u099a\u09cd\u099a\u09be\u09b0\u09a3 \u09a6\u09c7\u0996\u09be\u09a8',
            ),
            subtitle: _text(
              'Display English transliteration while reading Quran',
              '\u0995\u09c1\u09b0\u0986\u09a8 \u09aa\u09dc\u09be\u09b0 \u09b8\u09ae\u09df \u0987\u0982\u09b0\u09c7\u099c\u09bf \u0989\u099a\u09cd\u099a\u09be\u09b0\u09a3 \u09a6\u09c7\u0996\u09be\u09a8',
            ),
            value: enabled,
            onChanged: _setShowLatinLetters,
          );
        },
      ),
      Divider(height: 1, color: glass.glassBorder),
      ValueListenableBuilder2<bool, String>(
        first: showTranslationNotifier,
        second: translationLanguageNotifier,
        builder: (context, enabled, language, _) {
          return _switchRow(
            icon: Icons.translate_rounded,
            title: _text(
              'Show Translation',
              '\u0985\u09a8\u09c1\u09ac\u09be\u09a6 \u09a6\u09c7\u0996\u09be\u09a8',
            ),
            subtitle: _translationLanguageLabel(language),
            value: enabled,
            onChanged: (value) async {
              await _setShowTranslation(value);
              if (!value) return;
              await _pickTranslationLanguage(currentLanguage: language);
            },
            onTap: enabled
                ? () {
                    _pickTranslationLanguage(currentLanguage: language);
                  }
                : null,
          );
        },
      ),
      Divider(height: 1, color: glass.glassBorder),
      ValueListenableBuilder<bool>(
        valueListenable: showTajweedNotifier,
        builder: (context, enabled, _) {
          return _switchRow(
            icon: Icons.menu_book_outlined,
            title: _text(
              'Show Tajweed',
              '\u09a4\u09be\u099c\u09ac\u09c0\u09a6 \u09a6\u09c7\u0996\u09be\u09a8',
            ),
            subtitle: _text(
              'Click to view the tajweed detail',
              '\u09a4\u09be\u099c\u09ac\u09c0\u09a6\u09c7\u09b0 \u09ac\u09bf\u09b8\u09cd\u09a4\u09be\u09b0\u09bf\u09a4 \u09a6\u09c7\u0996\u09a4\u09c7 \u0995\u09cd\u09b2\u09bf\u0995 \u0995\u09b0\u09c1\u09a8',
            ),
            value: enabled,
            onChanged: _setShowTajweed,
          );
        },
      ),
    ];
  }
}
