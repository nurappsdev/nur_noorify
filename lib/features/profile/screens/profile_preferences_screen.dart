import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/admin/services/admin_role_service.dart';
import 'package:first_project/features/auth/services/auth_service.dart';
import 'package:first_project/features/family/models/family_member.dart';
import 'package:first_project/features/family/services/family_service.dart';
import 'package:first_project/features/profile/widgets/change_password_dialog.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/services/user_points_service.dart';
import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

part '../controllers/profile_prefs_state_mixin.dart';
part '../controllers/profile_prefs_settings_mixin.dart';
part '../controllers/profile_prefs_pickers_mixin.dart';
part '../controllers/profile_prefs_account_mixin.dart';
part '../widgets/profile_prefs_ui_mixin.dart';
part '../widgets/sections/profile_prefs_header_section_mixin.dart';
part '../widgets/sections/profile_prefs_family_section_mixin.dart';
part '../widgets/sections/profile_prefs_general_section_mixin.dart';
part '../widgets/sections/profile_prefs_prayer_section_b_mixin.dart';
part '../widgets/sections/profile_prefs_prayer_section_a_mixin.dart';
part '../widgets/sections/profile_prefs_quran_admin_section_mixin.dart';

class ProfilePreferencesScreen extends StatefulWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  State<ProfilePreferencesScreen> createState() =>
      _ProfilePreferencesScreenState();
}

class _ProfilePreferencesScreenState extends State<ProfilePreferencesScreen>
    with
        ProfilePrefsStateMixin,
        ProfilePrefsSettingsMixin,
        ProfilePrefsPickersMixin,
        ProfilePrefsAccountMixin,
        ProfilePrefsUiMixin,
        ProfilePrefsHeaderSectionMixin,
        ProfilePrefsFamilySectionMixin,
        ProfilePrefsGeneralSectionMixin,
        ProfilePrefsPrayerSectionBMixin,
        ProfilePrefsPrayerSectionAMixin,
        ProfilePrefsQuranAdminSectionMixin {
  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final glass = NoorifyGlassTheme(context);
    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 10.h),
                  children: [
                    ..._buildTitle(),
                    ..._buildProfileHeaderCard(),
                    ..._buildLeaderboardSection(),
                    ..._buildFamilySection(),
                    ..._buildNearbySection(),
                    ..._buildGeneralSection(),
                    ..._buildPrayerSettingSection(),
                    ..._buildQuranLearningSection(),
                    ..._buildAdminSection(),
                    ..._buildLogoutSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, child) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, child) => builder(context, a, b, child),
        );
      },
    );
  }
}
