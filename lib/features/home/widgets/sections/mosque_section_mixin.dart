part of '../../screens/daily_activity_screen.dart';

/// The "Nearby Mosques" preview card, backed by the cached Find Mosque results.
mixin DailyMosqueSectionMixin
    on
        State<DailyActivityScreen>,
        DailyActivityControllerMixin,
        DailyActivityViewBaseMixin {
  String _localizedDistance(double km) {
    final raw = km.toStringAsFixed(1);
    return _isBangla ? '${_toBanglaDigits(raw)} km' : '$raw km';
  }

  Widget _buildMosquePreviewCard() {
    final items = _nearbyMosquePreview.take(3).toList(growable: false);
    final hasData = items.isNotEmpty;

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _text('Nearby Mosques', 'নিকটবর্তী মসজিদ'),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openFindMosque,
                style: TextButton.styleFrom(
                  foregroundColor: _accentStrong,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(_text('View all', 'সব দেখুন')),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          InkWell(
            onTap: _openFindMosque,
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              constraints: BoxConstraints(minHeight: 132.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                gradient: LinearGradient(
                  colors: _isDarkTheme
                      ? const [Color(0xFF1A3045), Color(0xFF142435)]
                      : const [Color(0xFFF6FBFF), Color(0xFFE6F1F8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _isDarkTheme
                      ? const Color(0x334F7590)
                      : const Color(0xFFCFDFEA),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
                child: Column(
                  children: [
                    if (hasData) ...[
                      for (final item in items) ...[
                        _buildMosquePreviewPill(
                          name: item.name,
                          distance: _localizedDistance(item.distanceKm),
                        ),
                        if (item != items.last) SizedBox(height: 8.h),
                      ],
                    ] else ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(4.w, 10.h, 4.w, 14.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_searching_rounded,
                              size: 18.sp,
                              color: _textWeak,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _text(
                                  'Tap to sync your nearest mosque list',
                                  'নিকটবর্তী মসজিদের তালিকা সিঙ্ক করতে ট্যাপ করুন',
                                ),
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 10.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: _accentStrong,
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        child: Text(
                          _text(
                            hasData ? 'Updated list' : 'Find Mosque',
                            hasData ? 'আপডেটেড তালিকা' : 'মসজিদ খুঁজুন',
                          ),
                          style: TextStyle(
                            color: _isDarkTheme
                                ? const Color(0xFF042A31)
                                : Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_nearbyMosquePreviewUpdatedAt != null) ...[
            SizedBox(height: 6.h),
            Text(
              _text(
                'Last synced from Find Mosque',
                'Find Mosque থেকে সর্বশেষ সিঙ্ক',
              ),
              style: TextStyle(
                color: _textMuted,
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMosquePreviewPill({
    required String name,
    required String distance,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: _isDarkTheme ? const Color(0xB2122231) : const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(
          color: _isDarkTheme
              ? const Color(0x334F7590)
              : const Color(0xFFD1E1EC),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_city_rounded, size: 16.sp, color: _textWeak),
          SizedBox(width: 7.w),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            distance,
            style: TextStyle(
              color: _accentStrong,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
