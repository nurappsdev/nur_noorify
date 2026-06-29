import 'package:firebase_core/firebase_core.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/auth/services/auth_service.dart';

/// Resolves the route to land on once the splash/onboarding flow is done.
///
/// The app opens home for both guests and signed-in users. When a Firebase user
/// exists, we still sync the local profile before entering the home shell.
Future<String> resolvePostSplashRoute() async {
  if (Firebase.apps.isEmpty) {
    return RouteNames.home;
  }
  try {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      await AuthService.instance.syncLocalProfileFromCurrentUser();
    }
    return RouteNames.home;
  } catch (_) {
    return RouteNames.home;
  }
}
