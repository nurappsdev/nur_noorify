import 'package:flutter/material.dart';

import 'package:first_project/core/theme/brand_colors.dart';
import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/auth/services/auth_service.dart';
import 'package:first_project/shared/services/app_globals.dart';

Widget bottomNav(
  BuildContext context,
  int active, {
  ValueChanged<int>? onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isBangla = appLanguageNotifier.value == AppLanguage.bangla;
  String t(String en, String bn) => isBangla ? bn : en;
  final activeColor = isDark ? const Color(0xFF2EB8E6) : BrandColors.primary;
  final inactiveColor = isDark
      ? const Color(0xFFACC0CC)
      : const Color(0xFF728A98);

  final user = AuthService.instance.currentUser;
  final isGuest = user == null;

  final items = <({String label, IconData icon, String routeName})>[
    (
      label: t('Home', '\u09b9\u09cb\u09ae'),
      icon: Icons.home_filled,
      routeName: RouteNames.activity,
    ),
    if (!isGuest)
      (
        label: t('Leaderboard', '\u09b2\u09bf\u09a1\u09be\u09b0\u09ac\u09cb\u09b0\u09cd\u09a1'),
        icon: Icons.emoji_events_outlined,
        routeName: RouteNames.leaderboard,
      ),
    if (kQuranFeatureEnabled)
      (
        label: t('Quran', '\u0995\u09c1\u09b0\u0986\u09a8'),
        icon: Icons.menu_book_outlined,
        routeName: RouteNames.quran,
      ),
    (
      label: t('Dua Jikir', '\u09a6\u09cb\u09df\u09be \u099c\u09bf\u0995\u09bf\u09b0'),
      icon: Icons.self_improvement_outlined,
      routeName: RouteNames.prayerTimes,
    ),
    if (!isGuest)
      (
        label: t('Chat', '\u099a\u09cd\u09af\u09be\u099f'),
        icon: Icons.chat_bubble_outline,
        routeName: RouteNames.chat,
      ),
    (
      label: t('Profile', '\u09aa\u09cd\u09b0\u09cb\u09ab\u09be\u0987\u09b2'),
      icon: Icons.person_outline,
      routeName: RouteNames.preferences,
    ),
  ];

  // `active` already arrives as an index into the current `items` list
  // (app_routes and HomeShell compute it from kQuranFeatureEnabled), so we only
  // clamp it defensively rather than re-shifting it here.
  final normalizedActive = active.clamp(0, items.length - 1);

  void onTapItem(int index) {
    if (index == normalizedActive) return;
    if (onTap != null) {
      onTap(index);
      return;
    }
    // From a non-shell screen (e.g. a detail page): jump straight back to the
    // HomeShell at the requested tab, clearing the navigation stack so we
    // don't pile detail routes underneath the shell.
    final routeName = items[index].routeName;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  return Container(
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xEA0F1F29), Color(0xF4112029)]
            : const [Color(0xF8FFFFFF), Color(0xF0F8FCFF)],
      ),
      border: Border(
        top: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xC8D2E2ED),
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? const Color(0x30000000) : const Color(0x120E3853),
          blurRadius: 14,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isActive = index == normalizedActive;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTapItem(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: isDark ? 0.2 : 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(
                      color: activeColor.withValues(
                        alpha: isDark ? 0.42 : 0.34,
                      ),
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: isActive ? 22 : 20,
                  color: isActive ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ),
  );
}
