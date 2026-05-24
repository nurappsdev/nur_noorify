import 'package:flutter/material.dart';

import 'route_names.dart';
import 'package:first_project/features/profile/screens/edit_profile_screen.dart';
import 'package:first_project/features/legal/screens/about_screen.dart';
import 'package:first_project/features/admin/screens/admin_panel_screen.dart';
import 'package:first_project/features/asmaul_husna/screens/asma_screen.dart';
import 'package:first_project/features/dua/screens/dua_screen.dart';
import 'package:first_project/features/tasbih/screens/tasbih_screen.dart';
import 'package:first_project/features/hadith/screens/hadith_screen.dart';
import 'package:first_project/features/mosque/screens/find_mosque_screen.dart';
import 'package:first_project/features/legal/screens/privacy_policy_screen.dart';
import 'package:first_project/features/qibla/screens/qibla_compass_screen.dart';
import 'package:first_project/features/islamic_calendar/screens/islamic_calendar_screen.dart';
import 'package:first_project/features/splash/screens/ramadan_splash_screen.dart';
import 'package:first_project/features/auth/screens/signin_screen.dart';
import 'package:first_project/features/auth/screens/signup_screen.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/home_shell.dart';

class AppRoutes {
  // Index in HomeShell for each tab route. Kept in sync with the items list
  // in bottom_nav.dart and the tab list in HomeShell.
  static const int _tabHome = 0;
  static const int _tabDiscover = 1;
  static const int _tabQuran = 2;
  static int get _tabPrayer => kQuranFeatureEnabled ? 3 : 2;
  static int get _tabProfile => kQuranFeatureEnabled ? 4 : 3;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return _page(const HomeShell(initialIndex: _tabHome), settings);
      case RouteNames.splash:
        return _page(const RamadanSplashScreen(), settings);
      case RouteNames.signIn:
        return _page(const SignInScreen(), settings);
      case RouteNames.signUp:
        return _page(const SignupScreen(), settings);
      case RouteNames.preferences:
        return _page(HomeShell(initialIndex: _tabProfile), settings);
      case RouteNames.editProfile:
        return _page(const EditProfileScreen(), settings);
      case RouteNames.activity:
        return _page(const HomeShell(initialIndex: _tabHome), settings);
      case RouteNames.discover:
        return _page(const HomeShell(initialIndex: _tabDiscover), settings);
      case RouteNames.asma:
        return _page(const AsmaScreen(), settings);
      case RouteNames.hadith:
        return _page(const HadithScreen(), settings);
      case RouteNames.dua:
        return _page(const DuaScreen(), settings);
      case RouteNames.tasbih:
        return _page(const TasbihScreen(), settings);
      case RouteNames.quran:
        if (!kQuranFeatureEnabled) {
          return _page(const HomeShell(initialIndex: _tabHome), settings);
        }
        return _page(const HomeShell(initialIndex: _tabQuran), settings);
      case RouteNames.prayerTimes:
        return _page(HomeShell(initialIndex: _tabPrayer), settings);
      case RouteNames.islamicCalendar:
        return _page(const IslamicCalendarScreen(), settings);
      case RouteNames.prayerCompass:
        return _page(const QiblaCompassScreen(), settings);
      case RouteNames.findMosque:
        return _page(const FindMosqueScreen(), settings);
      case RouteNames.privacyPolicy:
        return _page(const PrivacyPolicyScreen(), settings);
      case RouteNames.about:
        return _page(const AboutScreen(), settings);
      case RouteNames.adminPanel:
        return _page(const AdminPanelScreen(), settings);
      default:
        return _page(const HomeShell(initialIndex: _tabHome), settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(
    Widget child,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<void>(builder: (_) => child, settings: settings);
  }
}
