part of '../screens/profile_preferences_screen.dart';

/// Account actions: edit profile, logout, and change password.
mixin ProfilePrefsAccountMixin
    on State<ProfilePreferencesScreen>, ProfilePrefsStateMixin {
  Future<void> _openEditProfile() async {
    await Navigator.of(context).pushNamed(RouteNames.editProfile);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_text('Logout', '\u09b2\u0997\u0986\u0989\u099f')),
          content: Text(
            _text(
              'Are you sure you want to logout now?',
              '\u0986\u09aa\u09a8\u09bf \u0995\u09bf \u098f\u0996\u09a8 \u09b2\u0997\u0986\u0989\u099f \u0995\u09b0\u09a4\u09c7 \u099a\u09be\u09a8?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_text('Cancel', '\u09ac\u09be\u09a4\u09bf\u09b2')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_text('Logout', '\u09b2\u0997\u0986\u0989\u099f')),
            ),
          ],
        );
      },
    );
    if (confirm != true || !mounted) return;
    try {
      await AuthService.instance.signOut();
    } catch (_) {
      // Keep logout flow usable even if sign out fails on a local-only session.
    }
    await clearUserProfile();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.signIn, (route) => false);
  }

  Future<void> _openChangePassword() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }
    final changed = await showChangePasswordDialog(context, text: _text);
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    }
  }
}
