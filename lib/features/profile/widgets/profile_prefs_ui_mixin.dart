part of '../screens/profile_preferences_screen.dart';

/// Reusable building blocks: avatar, section cards/labels, and rows.
mixin ProfilePrefsUiMixin
    on State<ProfilePreferencesScreen>, ProfilePrefsStateMixin {
  Widget _avatar() {
    return ValueListenableBuilder2<String?, String?>(
      first: profilePhotoBase64Notifier,
      second: profilePhotoUrlNotifier,
      builder: (context, encoded, photoUrl, _) {
        final glass = NoorifyGlassTheme(context);
        final bytes = _decodeProfilePhoto(encoded);
        final hasPhotoUrl = (photoUrl ?? '').trim().isNotEmpty;
        if (bytes != null) {
          return CircleAvatar(
            radius: 19.r,
            backgroundImage: MemoryImage(bytes),
            backgroundColor: Colors.white,
          );
        }
        if (hasPhotoUrl) {
          return CircleAvatar(
            radius: 19.r,
            backgroundImage: NetworkImage(photoUrl!.trim()),
            backgroundColor: Colors.white,
          );
        }
        return CircleAvatar(
          radius: 19.r,
          backgroundColor: glass.isDark
              ? const Color(0xFF2A3A4A)
              : const Color(0xFFCCD7E2),
          child: Icon(
            Icons.person,
            color: glass.isDark
                ? const Color(0xFFB6C9D8)
                : const Color(0xFF6B7A8A),
            size: 19.sp,
          ),
        );
      },
    );
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return NoorifyGlassCard(
      radius: BorderRadius.circular(14.r),
      padding: padding,
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    final glass = NoorifyGlassTheme(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(6.w, 12.h, 6.w, 6.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10.5.sp,
            color: glass.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _rowTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final glass = NoorifyGlassTheme(context);
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(icon, size: 16.sp, color: glass.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: glass.textPrimary,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: glass.textMuted,
                height: 1.2,
              ),
            ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: glass.textMuted,
            size: 18.sp,
          ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
      horizontalTitleGap: 10,
      minVerticalPadding: 6,
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    VoidCallback? onTap,
  }) {
    final glass = NoorifyGlassTheme(context);
    return _rowTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap ?? () => onChanged(!value),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: glass.accent,
        activeThumbColor: Colors.white,
        inactiveTrackColor: glass.isDark
            ? const Color(0x335F7E94)
            : const Color(0xFFD4DCE3),
        inactiveThumbColor: glass.isDark
            ? const Color(0xFF8AA8BC)
            : const Color(0xFF90A2AF),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
