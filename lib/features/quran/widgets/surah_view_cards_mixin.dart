part of '../screens/surah_detail_screen.dart';

/// The frosted-glass panel primitive and the surah intro/progress card.
mixin SurahDetailViewCardsMixin
    on
        State<SurahDetailScreen>,
        SurahDetailStateMixin,
        SurahDetailSheetsMixin {
  Widget _buildGlassPanel({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) {
    final resolvedPadding = padding ?? EdgeInsets.all(14.r);
    final resolvedRadius =
        borderRadius ?? BorderRadius.all(Radius.circular(18.r));
    return ClipRRect(
      borderRadius: resolvedRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: resolvedPadding,
          decoration: BoxDecoration(
            borderRadius: resolvedRadius,
            gradient: LinearGradient(
              colors: [_glassStart, _glassEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _glassBorder),
            boxShadow: [
              BoxShadow(
                color: _glassShadow,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSurahIntroCard({
    required QuranSurahDetail detail,
    required int totalAyah,
    required int activeAyahIndex,
  }) {
    final currentAyah = activeAyahIndex >= 0
        ? activeAyahIndex + 1
        : (_lastSavedAyahNo > 0 ? _lastSavedAyahNo : 1);
    final safeCurrentAyah = totalAyah <= 0
        ? 0
        : currentAyah.clamp(1, totalAyah);
    final progressValue = totalAyah <= 0 ? 0.0 : safeCurrentAyah / totalAyah;
    final ayahCountLabel = _toBanglaDigits(totalAyah.toString());
    final currentAyahLabel = _toBanglaDigits(safeCurrentAyah.toString());
    final bookmarkCount = _bookmarksByAyahNo.length;

    return _buildGlassPanel(
      borderRadius: BorderRadius.all(Radius.circular(18.r)),
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.surahNameArabicLong.trim().isEmpty
                ? detail.surahNameArabic
                : detail.surahNameArabicLong,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: _screenTextPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${detail.surahName} • ${_toBanglaDigits(detail.surahNo.toString())}',
            style: TextStyle(
              color: _screenTextSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(999.r),
            child: LinearProgressIndicator(
              minHeight: 5.h,
              value: progressValue,
              backgroundColor: _isDarkTheme
                  ? const Color(0x263A7FA1)
                  : const Color(0xFFDAEAF3),
              valueColor: AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Text(
                'Ayah $currentAyahLabel/$ayahCountLabel',
                style: TextStyle(
                  color: _screenTextPrimary,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(999.r),
                onTap: _openBookmarksScreen,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: _isDarkTheme
                        ? const Color(0x332EB8E6)
                        : const Color(0x1A1EA8B8),
                    borderRadius: BorderRadius.circular(999.r),
                    border: Border.all(color: _glassBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bookmarks_rounded, size: 14.sp, color: _accent),
                      SizedBox(width: 5.w),
                      Text(
                        '$bookmarkCount',
                        style: TextStyle(
                          color: _screenTextPrimary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
