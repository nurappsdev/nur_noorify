import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/admin/services/admin_role_service.dart';

/// Route to land on after a successful sign-in (or on app launch when a user
/// is already signed in): admins go straight to the admin dashboard, everyone
/// else to the normal home shell.
Future<String> resolvePostLoginRoute() async {
  try {
    final isAdmin = await AdminRoleService.instance.isCurrentUserAdmin();
    return isAdmin ? RouteNames.adminPanel : RouteNames.home;
  } catch (_) {
    return RouteNames.home;
  }
}
