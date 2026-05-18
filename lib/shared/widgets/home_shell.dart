import 'package:flutter/material.dart';

import 'package:first_project/features/discover/screens/discover_screen.dart';
import 'package:first_project/features/home/screens/daily_activity_screen.dart';
import 'package:first_project/features/prayer_time/screens/prayer_times_screen.dart';
import 'package:first_project/features/profile/screens/profile_preferences_screen.dart';
import 'package:first_project/features/quran/screens/quran_screen.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index;

  static const List<Widget> _tabsWithQuran = <Widget>[
    DailyActivityScreen(),
    DiscoverScreen(),
    QuranScreen(),
    PrayerTimesScreen(),
    ProfilePreferencesScreen(),
  ];

  static const List<Widget> _tabsWithoutQuran = <Widget>[
    DailyActivityScreen(),
    DiscoverScreen(),
    PrayerTimesScreen(),
    ProfilePreferencesScreen(),
  ];

  List<Widget> get _tabs =>
      kQuranFeatureEnabled ? _tabsWithQuran : _tabsWithoutQuran;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _tabs.length - 1);
  }

  void _onTabTap(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final safeIndex = _index.clamp(0, tabs.length - 1);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: safeIndex, children: tabs),
      bottomNavigationBar: SafeArea(
        top: false,
        child: bottomNav(context, safeIndex, onTap: _onTabTap),
      ),
    );
  }
}
