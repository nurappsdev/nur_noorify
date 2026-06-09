import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:first_project/features/onboarding/widgets/onboarding_scaffold.dart';
import 'package:first_project/features/splash/utils/post_splash_route.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

/// Final onboarding step: set up the device location used for prayer times, or
/// skip and keep the Dhaka fallback. Either path completes onboarding.
class OnboardingLocationScreen extends StatefulWidget {
  const OnboardingLocationScreen({super.key});

  @override
  State<OnboardingLocationScreen> createState() =>
      _OnboardingLocationScreenState();
}

class _OnboardingLocationScreenState extends State<OnboardingLocationScreen> {
  bool _busy = false;

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  String _t(String en, String bn) => _isBangla ? bn : en;

  Future<void> _setupLocation() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _notify(
          'Please enable phone location service.',
          'ফোনের লোকেশন সার্ভিস চালু করুন।',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _notify(
          'Location permission denied on this device.',
          'এই ডিভাইসে লোকেশন পারমিশন বন্ধ আছে।',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final label = await _resolveLabel(position);
      useDeviceLocationNotifier.value = true;
      if (label != null && label.isNotEmpty) {
        profileLocationNotifier.value = label;
      }
      await _finish();
    } catch (_) {
      _notify(
        'Could not read current location.',
        'বর্তমান লোকেশন পড়া যায়নি।',
      );
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  Future<String?> _resolveLabel(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      final city =
          place.locality ??
          place.subAdministrativeArea ??
          place.administrativeArea;
      final country = place.country;
      if (city == null || city.trim().isEmpty) return null;
      return country == null || country.trim().isEmpty
          ? city.trim()
          : '${city.trim()}, ${country.trim()}';
    } catch (_) {
      return null;
    }
  }

  Future<void> _finish() async {
    onboardingCompletedNotifier.value = true;
    await saveAppPreferences();
    final next = await resolvePostSplashRoute();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(next, (route) => false);
  }

  void _notify(String en, String bn) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_t(en, bn))));
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return OnboardingScaffold(
      step: 3,
      totalSteps: 3,
      title: _t('Setup Location', 'লোকেশন সেট করুন'),
      subtitle: _t(
        'We use your location for accurate prayer, Sehri, and Iftar times. '
            'Skip to use Dhaka, Bangladesh.',
        'নামাজ, সেহরি ও ইফতারের সঠিক সময়ের জন্য আমরা আপনার লোকেশন ব্যবহার করি। '
            'এড়িয়ে গেলে ঢাকা, বাংলাদেশ ব্যবহৃত হবে।',
      ),
      content: Center(
        child: Padding(
          padding: EdgeInsets.only(top: 12.h),
          child: NoorifyGlassCard(
            padding: EdgeInsets.all(26.r),
            radius: BorderRadius.circular(100.r),
            child: Icon(
              Icons.location_on_rounded,
              size: 56.sp,
              color: glass.accent,
            ),
          ),
        ),
      ),
      primaryLabel: _t('Setup Location', 'লোকেশন সেট করুন'),
      primaryBusy: _busy,
      onPrimary: _setupLocation,
      secondaryLabel: _t('Skip Now', 'এখন এড়িয়ে যান'),
      onSecondary: _busy ? null : _finish,
    );
  }
}
