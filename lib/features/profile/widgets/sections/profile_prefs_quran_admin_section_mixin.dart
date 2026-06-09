part of '../../screens/profile_preferences_screen.dart';

/// 'Quran Learning' card, admin section, and logout button.
mixin ProfilePrefsQuranAdminSectionMixin
    on
        State<ProfilePreferencesScreen>,
        ProfilePrefsStateMixin,
        ProfilePrefsUiMixin,
        ProfilePrefsSettingsMixin,
        ProfilePrefsPickersMixin,
        ProfilePrefsAccountMixin {
  List<Widget> _buildQuranLearningSection() {
    final glass = NoorifyGlassTheme(context);
    return [
      _sectionLabel(
        _text(
          'Quran Learning',
          '\u0995\u09c1\u09b0\u0986\u09a8 \u09b2\u09be\u09b0\u09cd\u09a8\u09bf\u0982',
        ),
      ),
      _sectionCard(
        child: ValueListenableBuilder<bool>(
          valueListenable: hifzModeEnabledNotifier,
          builder: (context, enabled, _) {
            return Column(
              children: [
                _switchRow(
                  icon: Icons.self_improvement_outlined,
                  title: _text(
                    'Enable Hifz Mode',
                    '\u09b9\u09bf\u09ab\u099c \u09ae\u09cb\u09a1 \u099a\u09be\u09b2\u09c1 \u0995\u09b0\u09c1\u09a8',
                  ),
                  subtitle: _text(
                    'Use repeat mode for ayah memorization',
                    '\u0986\u09df\u09be\u09a4 \u09ae\u09c1\u0996\u09b8\u09cd\u09a5\u09c7\u09b0 \u099c\u09a8\u09cd\u09af \u09b0\u09bf\u09aa\u09bf\u099f \u09ae\u09cb\u09a1 \u09ac\u09cd\u09af\u09ac\u09b9\u09be\u09b0 \u0995\u09b0\u09c1\u09a8',
                  ),
                  value: enabled,
                  onChanged: _setHifzMode,
                ),
                if (enabled) ...[
                  Divider(height: 1, color: glass.glassBorder),
                  ValueListenableBuilder<int>(
                    valueListenable: hifzRepeatCountNotifier,
                    builder: (context, repeatCount, _) {
                      return _rowTile(
                        icon: Icons.repeat_rounded,
                        title: _text(
                          'Hifz Repeat Count',
                          '\u09b9\u09bf\u09ab\u099c \u09b0\u09bf\u09aa\u09bf\u099f \u09b8\u0982\u0996\u09cd\u09af\u09be',
                        ),
                        subtitle: _text(
                          '${repeatCount}x per ayah',
                          '\u09aa\u09cd\u09b0\u09a4\u09bf \u0986\u09df\u09be\u09a4\u09c7 ${repeatCount}x',
                        ),
                        onTap: _selectHifzRepeatCount,
                      );
                    },
                  ),
                  Divider(height: 1, color: glass.glassBorder),
                  ValueListenableBuilder<bool>(
                    valueListenable: hifzHideBanglaMeaningNotifier,
                    builder: (context, hideBangla, _) {
                      return _switchRow(
                        icon: Icons.visibility_off_outlined,
                        title: _text(
                          'Hide Bangla in Hifz',
                          '\u09b9\u09bf\u09ab\u099c\u09c7 \u09ac\u09be\u0982\u09b2\u09be \u09b2\u09c1\u0995\u09be\u09a8',
                        ),
                        subtitle: _text(
                          'Show Arabic only while practicing',
                          '\u09aa\u09cd\u09b0\u09cd\u09af\u09be\u0995\u099f\u09bf\u09b8\u09c7 \u09b6\u09c1\u09a7\u09c1 \u0986\u09b0\u09ac\u09bf \u09a6\u09c7\u0996\u09be\u09a8',
                        ),
                        value: hideBangla,
                        onChanged: _setHifzHideBanglaMeaning,
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildAdminSection() {
    return [
      StreamBuilder<bool>(
        stream: _adminStream,
        builder: (context, snapshot) {
          final isAdmin = snapshot.data ?? false;
          if (!isAdmin) return const SizedBox.shrink();
          return Column(
            children: [
              _sectionLabel(
                _text(
                  'Admin',
                  '\u0985\u09cd\u09af\u09be\u09a1\u09ae\u09bf\u09a8',
                ),
              ),
              _sectionCard(
                child: _rowTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: _text(
                    'Admin Panel',
                    '\u0985\u09cd\u09af\u09be\u09a1\u09ae\u09bf\u09a8 \u09aa\u09cd\u09af\u09be\u09a8\u09c7\u09b2',
                  ),
                  subtitle: _text(
                    'Manage app announcements and modal banners',
                    '\u0985\u09cd\u09af\u09be\u09aa\u09c7\u09b0 \u0985\u09cd\u09af\u09be\u09a8\u09be\u0989\u09a8\u09cd\u09b8\u09ae\u09c7\u09a8\u09cd\u099f \u0993 \u09ae\u09cb\u09a1\u09be\u09b2 \u09ac\u09cd\u09af\u09be\u09a8\u09be\u09b0 \u09aa\u09b0\u09bf\u099a\u09be\u09b2\u09a8\u09be \u0995\u09b0\u09c1\u09a8',
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed(RouteNames.adminPanel);
                  },
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  List<Widget> _buildLogoutSection() {
    return [
      SizedBox(height: 16.h),
      Align(
        alignment: Alignment.center,
        child: FilledButton.icon(
          onPressed: _logout,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE64C5B),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 9.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22.r),
            ),
          ),
          icon: Icon(Icons.logout_rounded, size: 14.sp),
          label: Text(
            _text('Log Out', '\u09b2\u0997 \u0986\u0989\u099f'),
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ];
  }
}
