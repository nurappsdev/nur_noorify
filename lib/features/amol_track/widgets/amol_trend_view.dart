import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One day's column in a trend chart: its [score] out of [maxScore], a short
/// axis [label], and flags marking today / not-yet-arrived days.
class AmolTrendBar {
  const AmolTrendBar({
    required this.label,
    required this.score,
    required this.maxScore,
    required this.isToday,
    required this.isFuture,
  });

  final String label;
  final int score;
  final int maxScore;
  final bool isToday;
  final bool isFuture;

  double get fraction =>
      maxScore == 0 ? 0.0 : (score / maxScore).clamp(0.0, 1.0);
  int get percent => (fraction * 100).round();
}

/// A weekly/monthly amal trend card: a row of vertical bars showing each day's
/// completion percentage, with the period average called out at the top. Drawn
/// with plain widgets (no chart dependency) to match the rest of the tracker.
class AmolTrendView extends StatelessWidget {
  const AmolTrendView({
    super.key,
    required this.title,
    required this.bars,
    required this.averagePercent,
    required this.trackedDays,
    required this.isBangla,
    required this.isDark,
  });

  final String title;
  final List<AmolTrendBar> bars;
  final int averagePercent;

  /// Number of past-or-today days the average is computed over (future days in
  /// the period are excluded).
  final int trackedDays;

  final bool isBangla;
  final bool isDark;

  Color _c(int dark, int light) => Color(isDark ? dark : light);

  Color get _textPrimary => _c(0xFFFFFFFF, 0xFF143349);
  Color get _textSecondary => _c(0xFF9BC1D8, 0xFF5F7E94);
  Color get _textMuted => _c(0xFF6E8DA3, 0xFF8AA2B4);
  Color get _accent => _c(0xFF1FD5C0, 0xFF1EA8B8);
  Color get _gold => _c(0xFFE6C77A, 0xFFB78A2E);
  Color get _trackBg => _c(0xFF1B2D3E, 0xFFD8E7F1);
  Color get _cardStart => _c(0xFF121F2E, 0xFFFFFFFF);
  Color get _cardEnd => _c(0xFF0D1824, 0xFFF2F8FD);
  Color get _cardBorder => _c(0x22D2F4FF, 0xFFDCE9F2);

  String _digits(String input) {
    if (!isBangla) return input;
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      final code = ch.codeUnitAt(0);
      if (code >= 0x30 && code <= 0x39) {
        buffer.write(bn[code - 0x30]);
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  String _t(String en, String bn) => isBangla ? bn : en;

  @override
  Widget build(BuildContext context) {
    // Thin the axis labels when there are many bars (a month) so they stay
    // readable: only every 5th day plus the last keeps its label.
    final dense = bars.length > 10;

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [_cardStart, _cardEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: _gold, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _averageBadge(),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            trackedDays == 0
                ? _t('No tracked days yet in this period',
                    'এই সময়ে এখনও কোনো দিন ট্র্যাক করা হয়নি')
                : _t(
                    'Average over $trackedDays day${trackedDays == 1 ? '' : 's'}',
                    '$trackedDays দিনের গড়',
                  ),
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 132.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < bars.length; i++)
                  Expanded(
                    child: _buildBar(
                      bars[i],
                      showLabel: !dense || i % 5 == 0 || i == bars.length - 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _averageBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0x55E6C77A), Color(0x3320D3BF)]
              : const [Color(0x33B78A2E), Color(0x1F1EA8B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: _gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${_digits(averagePercent.toString())}%',
        style: TextStyle(
          color: isDark ? const Color(0xFFF5E2B8) : const Color(0xFF7A5A1F),
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildBar(AmolTrendBar bar, {required bool showLabel}) {
    const trackHeight = 96.0;
    final fillColor = bar.isToday ? _gold : _accent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!bar.isFuture && bar.score > 0)
            Text(
              _digits(bar.percent.toString()),
              style: TextStyle(
                color: _textSecondary,
                fontSize: 8.5.sp,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            SizedBox(height: 8.5.sp + 2),
          SizedBox(height: 3.h),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: SizedBox(
                  width: double.infinity,
                  height: trackHeight.h,
                  child: Stack(
                    children: [
                      Container(color: _trackBg),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: bar.isFuture ? 0.0 : bar.fraction,
                          child: Container(color: fillColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            showLabel ? _digits(bar.label) : '',
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: bar.isToday ? _accent : _textMuted,
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
