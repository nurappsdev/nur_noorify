import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/chat/screens/chat_users_screen.dart';
import 'package:first_project/features/discover/screens/discover_screen.dart';
import 'package:first_project/features/dua_jikir/screens/dua_jikir_screen.dart';
import 'package:first_project/features/home/screens/daily_activity_screen.dart';
import 'package:first_project/features/profile/screens/profile_preferences_screen.dart';
import 'package:first_project/features/quran/screens/quran_screen.dart';
import 'package:first_project/shared/providers/bottom_nav_provider.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const List<Widget> _tabsWithQuran = <Widget>[
    DailyActivityScreen(),
    DiscoverScreen(),
    QuranScreen(),
    DuaJikirScreen(),
    ChatUsersScreen(),
    ProfilePreferencesScreen(),
  ];

  static const List<Widget> _tabsWithoutQuran = <Widget>[
    DailyActivityScreen(),
    DiscoverScreen(),
    DuaJikirScreen(),
    ChatUsersScreen(),
    ProfilePreferencesScreen(),
  ];

  List<Widget> get _tabs =>
      kQuranFeatureEnabled ? _tabsWithQuran : _tabsWithoutQuran;

  @override
  void initState() {
    super.initState();
    final clamped = widget.initialIndex.clamp(0, _tabs.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BottomNavProvider>().setIndex(clamped);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final navIndex = context.watch<BottomNavProvider>().currentIndex;
    final safeIndex = navIndex.clamp(0, tabs.length - 1);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: safeIndex, children: tabs),
      bottomNavigationBar: SafeArea(
        top: false,
        child: bottomNav(
          context,
          safeIndex,
          onTap: (i) => context.read<BottomNavProvider>().setIndex(i),
        ),
      ),
    );
  }
}
