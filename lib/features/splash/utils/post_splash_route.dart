import 'package:firebase_core/firebase_core.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/auth/services/auth_service.dart';
import 'package:first_project/features/auth/utils/post_login_route.dart';

/// Resolves the route to land on once the splash/onboarding flow is done.
///
/// Guests open home. When a Firebase user exists we sync the local profile
/// first, then admins land on the admin dashboard and everyone else on home.
Future<String> resolvePostSplashRoute() async {
  if (Firebase.apps.isEmpty) {
    return RouteNames.home;
  }
  try {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      await AuthService.instance.syncLocalProfileFromCurrentUser();
      return await resolvePostLoginRoute();
    }
    return RouteNames.home;
  } catch (_) {
    return RouteNames.home;
  }
}
