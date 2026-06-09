part of '../../screens/profile_preferences_screen.dart';

/// Screen title, profile summary card, and the 'Nearby' section.
mixin ProfilePrefsHeaderSectionMixin
    on
        State<ProfilePreferencesScreen>,
        ProfilePrefsStateMixin,
        ProfilePrefsUiMixin,
        ProfilePrefsAccountMixin {
  List<Widget> _buildTitle() {
    final glass = NoorifyGlassTheme(context);
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 6.h),
        child: Text(
          _text('Profile', '\u09aa\u09cd\u09b0\u09cb\u09ab\u09be\u0987\u09b2'),
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: glass.textPrimary,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildProfileHeaderCard() {
    final glass = NoorifyGlassTheme(context);
    return [
      _sectionCard(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        child: Row(
          children: [
            _avatar(),
            SizedBox(width: 11.w),
            Expanded(
              child: InkWell(
                onTap: _openEditProfile,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: profileNameNotifier,
                      builder: (context, name, _) {
                        final displayName = name.trim().isEmpty
                            ? _text(
                                'Add your name',
                                '\u0986\u09aa\u09a8\u09be\u09b0 \u09a8\u09be\u09ae \u09af\u09cb\u0997 \u0995\u09b0\u09c1\u09a8',
                              )
                            : name.trim();
                        return Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: glass.textPrimary,
                            fontSize: 13.sp,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 1.h),
                    ValueListenableBuilder<String>(
                      valueListenable: profileLocationNotifier,
                      builder: (context, location, _) {
                        return Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: _teal,
                              size: 12.sp,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  color: _teal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: glass.textMuted,
                              size: 16.sp,
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 4.h),
                    StreamBuilder<int>(
                      stream: UserPointsService.instance.watchPoints(),
                      builder: (context, snapshot) {
                        final points = snapshot.data ?? 0;
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: _teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: _teal.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: _teal,
                                size: 13.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '$points ${_text('points', 'পয়েন্ট')}',
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  color: _teal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: _openEditProfile,
              icon: Icon(
                Icons.edit_outlined,
                size: 17.sp,
                color: glass.textMuted,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildNearbySection() {
    return [
      _sectionLabel(
        _text('Nearby', '\u0986\u09b6\u09c7\u09aa\u09be\u09b6\u09c7'),
      ),
      _sectionCard(
        child: _rowTile(
          icon: Icons.mosque_rounded,
          title: _text(
            'Find Mosque',
            '\u09ae\u09b8\u099c\u09bf\u09a6 \u0996\u09c1\u0981\u099c\u09c1\u09a8',
          ),
          subtitle: _text(
            'Open nearest mosque and sync recent results',
            '\u09a8\u09bf\u0995\u099f\u09ac\u09b0\u09cd\u09a4\u09c0 \u09ae\u09b8\u099c\u09bf\u09a6 \u0996\u09c1\u09b2\u09c1\u09a8 \u098f\u09ac\u0982 \u09b8\u09be\u09ae\u09cd\u09aa\u09cd\u09b0\u09a4\u09bf\u0995 \u09ab\u09b2\u09be\u09ab\u09b2 \u09b8\u09bf\u0999\u09cd\u0995 \u0995\u09b0\u09c1\u09a8',
          ),
          onTap: () {
            Navigator.of(context).pushNamed(RouteNames.findMosque);
          },
        ),
      ),
    ];
  }
}
