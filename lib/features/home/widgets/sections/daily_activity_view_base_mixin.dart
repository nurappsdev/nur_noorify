part of '../../screens/daily_activity_screen.dart';

/// Shared building blocks for the home sections: language-aware text, the
/// theme-derived colour palette, the frosted glass card, and ornament helpers.
/// Every section mixin builds on top of this so the visual language stays
/// consistent across the screen.
mixin DailyActivityViewBaseMixin
    on State<DailyActivityScreen>, DailyActivityControllerMixin {
  bool _looksMojibake(String value) {
    for (final unit in value.codeUnits) {
      if (unit == 0x00C3 ||
          unit == 0x00C2 ||
          unit == 0x00E0 ||
          unit == 0x00D8 ||
          unit == 0x00D9 ||
          unit == 0x00D0 ||
          unit == 0x00E2) {
        return true;
      }
    }
    return false;
  }

  String _repairMojibake(String value) {
    var output = value;
    for (var i = 0; i < 2; i++) {
      if (!_looksMojibake(output)) break;
      try {
        output = utf8.decode(latin1.encode(output));
      } catch (_) {
        break;
      }
    }
    return output;
  }

  bool _containsBangla(String value) {
    return RegExp(r'[ঀ-৿]').hasMatch(value);
  }

  String _text(String english, String bangla) {
    if (!_isBangla) return english;
    final repaired = _repairMojibake(bangla);
    if (_looksMojibake(repaired)) return english;
    return _containsBangla(repaired) ? repaired : english;
  }

  bool get _isDarkTheme => Theme.of(context).brightness == Brightness.dark;

  Color get _glassStart =>
      _isDarkTheme ? const Color(0xFF121F2E) : const Color(0xF7FFFFFF);
  Color get _glassEnd =>
      _isDarkTheme ? const Color(0xFF0D1824) : const Color(0xDBF2F8FD);
  Color get _glassBorder =>
      _isDarkTheme ? const Color(0x22D2F4FF) : const Color(0xCCFFFFFF);
  Color get _glassShadow =>
      _isDarkTheme ? const Color(0x50000000) : const Color(0x260E3853);

  Color get _textPrimary =>
      _isDarkTheme ? Colors.white : const Color(0xFF143349);
  Color get _textSecondary =>
      _isDarkTheme ? const Color(0xFF9BC1D8) : const Color(0xFF5F7E94);
  Color get _textMuted =>
      _isDarkTheme ? const Color(0xFF88AFC7) : const Color(0xFF4D6B82);
  Color get _textWeak =>
      _isDarkTheme ? const Color(0xFFAFC4D4) : const Color(0xFF5D7C91);

  Color get _accentStrong =>
      _isDarkTheme ? const Color(0xFF1FD5C0) : const Color(0xFF1EA8B8);
  Color get _accentSoft =>
      _isDarkTheme ? const Color(0xFF7ED9EE) : const Color(0xFF2EA2BF);
  Color get _accentGold =>
      _isDarkTheme ? const Color(0xFFE6C77A) : const Color(0xFFB78A2E);
  Color get _accentGoldSoft =>
      _isDarkTheme ? const Color(0x66E6C77A) : const Color(0x66B78A2E);

  Color get _surfaceSubtle =>
      _isDarkTheme ? const Color(0xFF172A3A) : const Color(0xECFFFFFF);
  Color get _surfaceStrong =>
      _isDarkTheme ? const Color(0xFF162433) : const Color(0xFFE8F2F8);
  Color get _surfaceBorder =>
      _isDarkTheme ? const Color(0x334F7590) : const Color(0xFFD1E1EC);

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadiusGeometry? radius,
    bool ornamentedCorners = false,
  }) {
    final resolvedPadding = padding ?? EdgeInsets.all(14.r);
    final resolvedRadius = radius ?? BorderRadius.all(Radius.circular(18.r));
    final card = ClipRRect(
      borderRadius: resolvedRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
                blurRadius: 24.r,
                offset: Offset(0, 12.h),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (!ornamentedCorners) return card;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(top: -2.h, right: 14.w, child: _cornerOrnament()),
        Positioned(bottom: -2.h, left: 14.w, child: _cornerOrnament()),
      ],
    );
  }

  Widget _cornerOrnament() {
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: 8.w,
        height: 8.h,
        decoration: BoxDecoration(
          color: _accentGold,
          borderRadius: BorderRadius.circular(1.5.r),
          boxShadow: [
            BoxShadow(
              color: _accentGoldSoft,
              blurRadius: 8.r,
              spreadRadius: 0.5.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ornamentDivider({EdgeInsetsGeometry? padding}) {
    final line = Expanded(
      child: Container(
        height: 1.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _accentGoldSoft.withValues(alpha: 0),
              _accentGoldSoft,
              _accentGoldSoft.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          line,
          SizedBox(width: 8.w),
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 6.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: _accentGold,
                borderRadius: BorderRadius.circular(1.r),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          line,
        ],
      ),
    );
  }

  String _skyClock(DateTime? t) =>
      t == null ? '--:--' : _localizedPrayerTime(_formatPrayerTime(t));
}
