import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/splash/utils/post_splash_route.dart';
import 'package:first_project/shared/services/app_globals.dart';

class RamadanSplashScreen extends StatefulWidget {
  const RamadanSplashScreen({super.key});

  @override
  State<RamadanSplashScreen> createState() => _RamadanSplashScreenState();
}

class _RamadanSplashScreenState extends State<RamadanSplashScreen> {
  static const _splashDuration = Duration(milliseconds: 1800);
  static const _openingImagePath = 'assets/images/app-opening-page.jpg';

  @override
  void initState() {
    super.initState();
    _openNextAfterDelay();
  }

  Future<void> _openNextAfterDelay() async {
    await Future<void>.delayed(_splashDuration);
    if (!mounted) return;
    // First launch shows the onboarding flow; afterwards we go straight to the
    // auth gate. Onboarding resolves the post-splash route itself when it ends.
    final nextRoute = onboardingCompletedNotifier.value
        ? await resolvePostSplashRoute()
        : RouteNames.onboardingHadith;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          _openingImagePath,
          key: const Key('opening_splash_image'),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                'Noorify',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
