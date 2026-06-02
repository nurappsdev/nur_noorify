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
          Icon(Icons.menu_book_rounded, color: _accentSoft, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedLastReadLabel(),
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _lastReadPrimaryLine(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (secondary != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _openLastRead,
            style: FilledButton.styleFrom(
              backgroundColor: _accentStrong,
              foregroundColor: _isDarkTheme
                  ? const Color(0xFF032F35)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            child: Text(_localizedContinueLabel()),
          ),
        ],
      ),
    );
  }
}
