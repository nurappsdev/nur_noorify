import 'package:firebase_core/firebase_core.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/auth/services/auth_service.dart';
import 'package:first_project/shared/services/app_globals.dart';

/// Resolves the route to land on once the splash/onboarding flow is done.
///
/// Mirrors the auth gate: a signed-in user (or one who skipped the gate) goes
/// home, otherwise they go to sign in. Falls back to home if Firebase is
/// unavailable or auth lookup fails.
Future<String> resolvePostSplashRoute() async {
  if (Firebase.apps.isEmpty) {
    return skipAuthGateNotifier.value ? RouteNames.home : RouteNames.signIn;
  }
  try {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      await AuthService.instance.syncLocalProfileFromCurrentUser();
    }
    return skipAuthGateNotifier.value || user != null
        ? RouteNames.home
        : RouteNames.signIn;
  } catch (_) {
    return RouteNames.home;
  }
}
