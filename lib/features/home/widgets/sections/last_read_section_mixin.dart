part of '../../screens/daily_activity_screen.dart';

/// The "Last Read" Quran resume card (shown only when the Quran feature is on).
mixin DailyLastReadSectionMixin
    on
        State<DailyActivityScreen>,
        DailyActivityControllerMixin,
        DailyActivityViewBaseMixin {
  Widget _buildLastReadCard() {
    final secondary = _lastReadSecondaryLine();

    return _buildGlassCard(
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, color: _accentSoft, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedLastReadLabel(),
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  _lastReadPrimaryLine(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (secondary != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          FilledButton(
            onPressed: _openLastRead,
            style: FilledButton.styleFrom(
              backgroundColor: _accentStrong,
              foregroundColor: _isDarkTheme
                  ? const Color(0xFF032F35)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999.r),
              ),
              textStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
              ),
            ),
            child: Text(_localizedContinueLabel()),
          ),
        ],
      ),
    );
  }
}
