part of '../../screens/daily_activity_screen.dart';

/// The paired daily-activity progress stat cards (Alms, Quran recitation).
mixin DailyActivitySectionMixin
    on
        State<DailyActivityScreen>,
        DailyActivityControllerMixin,
        DailyActivityViewBaseMixin {
  String _localizedCount(int value) {
    final raw = value.toString();
    return _isBangla ? _toBanglaDigits(raw) : raw;
  }

  Widget _buildDailyActivityCard() {
    final items = _activities;
    // Both activity cards share the same row so they stay visible together,
    // side by side, without scrolling between them. IntrinsicHeight keeps the
    // two cards the same height even when their titles wrap differently.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(child: _buildActivityStatCard(items[i])),
            if (i != items.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityStatCard(ActivityItem item) {
    final progress = item.total == 0 ? 0.0 : item.done / item.total;
    final clamped = progress.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _surfaceStrong,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _activityIcon(item.title),
                  color: _accentSoft,
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                _isBangla
                    ? '${_toBanglaDigits(percent.toString())}%'
                    : '$percent%',
                style: TextStyle(
                  color: _accentStrong,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 7,
              backgroundColor: _isDarkTheme
                  ? const Color(0xFF1B2D3E)
                  : const Color(0xFFD8E7F1),
              valueColor: AlwaysStoppedAnimation<Color>(_accentStrong),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_localizedCount(item.done)}/${_localizedCount(item.total)}',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _activityIcon(String title) {
    final value = title.toLowerCase();
    if (value.contains('alms') || value.contains('zakat')) {
      return Icons.volunteer_activism_rounded;
    }
    if (value.contains('quran') || value.contains('recite')) {
      return Icons.menu_book_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }
}
