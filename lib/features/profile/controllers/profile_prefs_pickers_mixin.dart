part of '../screens/profile_preferences_screen.dart';

/// Modal bottom-sheet pickers for font size, translation language, etc.
mixin ProfilePrefsPickersMixin
    on
        State<ProfilePreferencesScreen>,
        ProfilePrefsStateMixin,
        ProfilePrefsSettingsMixin {
  Future<void> _pickTranslationLanguage({
    required String currentLanguage,
  }) async {
    final currentOption = _isBangla && currentLanguage == 'Bangla'
        ? '\u09ac\u09be\u0982\u09b2\u09be'
        : currentLanguage;
    final selected = await _pickOption(
      title: _text(
        'Translation Language',
        '\u0985\u09a8\u09c1\u09ac\u09be\u09a6\u09c7\u09b0 \u09ad\u09be\u09b7\u09be',
      ),
      options: _isBangla
          ? const ['\u09ac\u09be\u0982\u09b2\u09be', 'English']
          : const ['English', 'Bangla'],
      current: currentOption,
    );
    if (selected == null) return;
    final normalizedSelected = selected == '\u09ac\u09be\u0982\u09b2\u09be'
        ? 'Bangla'
        : selected;
    if (normalizedSelected == currentLanguage) return;
    translationLanguageNotifier.value = normalizedSelected;
    await saveAppPreferences();
  }

  Future<void> _selectHifzRepeatCount() async {
    final current = '${hifzRepeatCountNotifier.value}x';
    final selected = await _pickOption(
      title: _text(
        'Hifz Repeat Count',
        '\u09b9\u09bf\u09ab\u099c \u09b0\u09bf\u09aa\u09bf\u099f \u09b8\u0982\u0996\u09cd\u09af\u09be',
      ),
      options: const ['1x', '3x', '5x', '10x'],
      current: current,
    );
    if (selected == null) return;
    final parsed = int.tryParse(selected.replaceAll('x', ''));
    if (parsed == null || parsed == hifzRepeatCountNotifier.value) return;
    hifzRepeatCountNotifier.value = parsed;
    await saveAppPreferences();
  }

  Future<String?> _pickOption({
    required String title,
    required List<String> options,
    required String current,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              ...options.map((option) {
                final selected = option == current;
                return ListTile(
                  title: Text(option),
                  trailing: selected
                      ? Icon(Icons.check, color: _teal)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectFontSize() async {
    final current = appFontSizeNotifier.value;
    final selected = await showModalBottomSheet<AppFontSize>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  _text(
                    'Font Size',
                    '\u09ab\u09a8\u09cd\u099f \u09b8\u09be\u0987\u099c',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              ...AppFontSize.values.map((size) {
                final selected = size == current;
                return ListTile(
                  title: Text(_fontSizeLabel(size)),
                  trailing: selected
                      ? Icon(Icons.check, color: _teal)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(size),
                );
              }),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == current) return;
    await _setFontSize(selected);
  }
}
