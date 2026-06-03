part of '../../screens/daily_activity_screen.dart';

/// The top header card: greeting, profile avatar/name, location row with
/// refresh, and the time + date line.
mixin DailyHeaderSectionMixin
    on
        State<DailyActivityScreen>,
        DailyActivityControllerMixin,
        DailyActivityViewBaseMixin {
  String _greetingText() {
    final hour = _now.hour;
    if (hour < 12) return _text('Assalamu Alaikum,', 'আসসালামু আলাইকুম,');
    if (hour < 17) return _text('Good Afternoon,', 'শুভ অপরাহ্ন,');
    return _text('Good Evening,', 'শুভ সন্ধ্যা,');
  }

  String _profileDisplayName([String? rawName]) {
    final value = (rawName ?? profileNameNotifier.value).trim();
    return value;
  }

  bool _hasProfileName([String? rawName]) =>
      _profileDisplayName(rawName).isNotEmpty;

  String _profileInitial([String? rawName]) {
    final name = _profileDisplayName(rawName);
    return name.isEmpty ? 'N' : name[0].toUpperCase();
  }

  ImageProvider<Object>? _profileAvatarImage({
    String? encodedPhoto,
    String? remotePhotoUrl,
  }) {
    final encoded = (encodedPhoto ?? profilePhotoBase64Notifier.value ?? '')
        .trim();
    if (encoded.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(encoded));
      } catch (_) {
        // Fallback to url/default avatar when local image data is invalid.
      }
    }

    final remoteUrl = (remotePhotoUrl ?? profilePhotoUrlNotifier.value ?? '')
        .trim();
    if (remoteUrl.isNotEmpty) {
      return NetworkImage(remoteUrl);
    }
    return null;
  }

  Widget _buildTopHeader() {
    return _buildGlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      ornamentedCorners: true,
      child: Column(
        children: [
          Row(
            children: [
              ValueListenableBuilder<String>(
                valueListenable: profileNameNotifier,
                builder: (context, profileName, child) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: profilePhotoBase64Notifier,
                    builder: (context, profilePhotoBase64, child) {
                      return ValueListenableBuilder<String?>(
                        valueListenable: profilePhotoUrlNotifier,
                        builder: (context, profilePhotoUrl, child) {
                          final profileImage = _profileAvatarImage(
                            encodedPhoto: profilePhotoBase64,
                            remotePhotoUrl: profilePhotoUrl,
                          );
                          final hasName = _hasProfileName(profileName);
                          return Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _isDarkTheme
                                      ? const Color(0xFF1A2F45)
                                      : const Color(0xFFDDEBF5),
                                  backgroundImage: profileImage,
                                  child: profileImage == null
                                      ? (hasName
                                            ? Text(
                                                _profileInitial(profileName),
                                                style: TextStyle(
                                                  color: _isDarkTheme
                                                      ? Colors.white
                                                      : const Color(0xFF183247),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              )
                                            : Icon(
                                                Icons.auto_awesome_rounded,
                                                size: 18,
                                                color: _isDarkTheme
                                                    ? const Color(0xFF9EE7F4)
                                                    : const Color(0xFF1EA8B8),
                                              ))
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.nightlight_round,
                                            size: 12,
                                            color: _accentGold,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              _greetingText(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: _isDarkTheme
                                                    ? const Color(0xB3D8E5F7)
                                                    : const Color(0xFF4B687F),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      if (hasName)
                                        Text(
                                          _profileDisplayName(profileName),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: _textPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            height: 1,
                                          ),
                                        )
                                      else
                                        InkWell(
                                          onTap: () => Navigator.of(
                                            context,
                                          ).pushNamed(RouteNames.editProfile),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _isDarkTheme
                                                  ? const Color(0x2D2EB8E6)
                                                  : const Color(0x251EA8B8),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: _isDarkTheme
                                                    ? const Color(0x6659C8E4)
                                                    : const Color(0x66A7D7E2),
                                              ),
                                            ),
                                            child: Text(
                                              _text(
                                                'Set your profile name',
                                                'Set your profile name',
                                              ),
                                              style: TextStyle(
                                                color: _accentSoft,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              Material(
                color: _isDarkTheme
                    ? const Color(0xFF193048)
                    : const Color(0xE8FFFFFF),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () =>
                      Navigator.of(context).pushNamed(RouteNames.preferences),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: _isDarkTheme
                          ? const Color(0xFFB6CFE5)
                          : const Color(0xFF47677E),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: _isDarkTheme
                    ? const Color(0xFF8FB5CC)
                    : const Color(0xFF5D7B93),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _isDarkTheme
                        ? const Color(0xFFB6CFE5)
                        : const Color(0xFF56758E),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: _refreshLocationFromHeader,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _isDarkTheme
                        ? const Color(0xFF1B344A)
                        : const Color(0xE8FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _isDarkTheme
                          ? const Color(0x3359C8E4)
                          : const Color(0x66B7D5E6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 13, color: _accentSoft),
                      const SizedBox(width: 4),
                      Text(
                        _text('Refresh', 'রিফ্রেশ'),
                        style: TextStyle(
                          color: _accentSoft,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formattedTime,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  _activeHeaderDate,
                  maxLines: 2,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _isBangla
                  ? '$_formattedHijriDate | $_formattedBanglaDate'
                  : '$_formattedHijriDate | $_formattedBritishDate',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCalendarWaqtButton(),
        ],
      ),
    );
  }

  /// Full-width call-to-action that opens the month-at-a-glance Calendar & Waqt
  /// screen, seeded with the home screen's resolved location.
  Widget _buildCalendarWaqtButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => CalendarWaqtScreen(
              latitude: _latitude,
              longitude: _longitude,
              locationLabel: _locationLabel,
            ),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isDarkTheme
                  ? const [Color(0xFF13404B), Color(0xFF0F2F3A)]
                  : const [Color(0xFFE3F4F7), Color(0xFFD3ECF1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDarkTheme
                  ? const Color(0x3359C8E4)
                  : const Color(0x66A7D7E2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 17,
                color: _accentStrong,
              ),
              const SizedBox(width: 8),
              Text(
                _text('Calendar & Waqt', 'ক্যালেন্ডার ও ওয়াক্ত'),
                style: TextStyle(
                  color: _accentStrong,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
