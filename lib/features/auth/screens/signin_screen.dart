import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/core/utils/network_utils.dart';
import 'package:first_project/features/auth/services/auth_service.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const _bgPath = 'assets/images/Login.jpg';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _guestNameController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;
  String _text(String en, String bn) => _isBangla ? bn : en;

  @override
  void initState() {
    super.initState();
    appLanguageNotifier.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  InputDecoration _fieldStyle(
    NoorifyGlassTheme glass, {
    required String label,
    required String hint,
    required Widget suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: glass.textMuted, fontSize: 10.sp),
      hintText: hint,
      hintStyle: TextStyle(
        color: glass.textSecondary,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: glass.isDark
          ? const Color(0x3F122634)
          : const Color(0xDFFFFFFF),
      suffixIcon: suffixIcon,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: glass.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: glass.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: glass.accent.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _authShell(BuildContext context, Widget child) {
    final glass = NoorifyGlassTheme(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _bgPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [glass.bgTop, glass.bgMid, glass.bgBottom],
              ),
            ),
          ),
        ),
        Container(
          color: Colors.black.withValues(alpha: glass.isDark ? 0.45 : 0.2),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(color: Colors.transparent),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.r),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 360.w),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _orDivider(NoorifyGlassTheme glass) {
    return Row(
      children: [
        Expanded(child: Divider(color: glass.glassBorder)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Text(
            _text('OR', '\u0985\u09a5\u09ac\u09be'),
            style: TextStyle(
              color: glass.textMuted,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: glass.glassBorder)),
      ],
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _ensureInternetOrShowMessage() async {
    final online = await NetworkUtils.hasInternet();
    if (!online) {
      _showMessage(
        _text(
          'No internet connection. Please check network and try again.',
          '\u0987\u09a8\u09cd\u099f\u09be\u09b0\u09a8\u09c7\u099f \u09b8\u0982\u09af\u09cb\u0997 \u09a8\u09c7\u0987\u0964 \u09a8\u09c7\u099f\u0993\u09df\u09be\u09b0\u09cd\u0995 \u099a\u09c7\u0995 \u0995\u09b0\u09c7 \u0986\u09ac\u09be\u09b0 \u099a\u09c7\u09b7\u09cd\u099f\u09be \u0995\u09b0\u09c1\u09a8\u0964',
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _setSkipAuthGate(bool value) async {
    skipAuthGateNotifier.value = value;
    await saveAppPreferences();
  }

  Future<
    ({String name, AppLanguage language, bool prayerAlerts, bool mealAlerts})?
  >
  _promptGuestQuickSetup() async {
    _guestNameController.clear();
    var language = appLanguageNotifier.value;
    var prayerAlerts = prayerAlertsEnabledNotifier.value;
    var mealAlerts =
        sehriAlertEnabledNotifier.value || iftarAlertEnabledNotifier.value;

    final result = await showDialog<({String name, AppLanguage language, bool prayerAlerts, bool mealAlerts})?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                _text(
                  'Guest Quick Setup',
                  '\u0997\u09c7\u09b8\u09cd\u099f \u0995\u09cd\u09ac\u09bf\u0995 \u09b8\u09c7\u099f\u0986\u09aa',
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(
                        'You can set these now and change later from Profile.',
                        '\u098f\u0997\u09c1\u09b2\u09cb \u098f\u0996\u09a8 \u09b8\u09c7\u099f \u0995\u09b0\u09c1\u09a8, \u09aa\u09b0\u09c7 \u09aa\u09cd\u09b0\u09cb\u09ab\u09be\u0987\u09b2 \u09a5\u09c7\u0995\u09c7 \u09ac\u09a6\u09b2\u09be\u09a4\u09c7 \u09aa\u09be\u09b0\u09ac\u09c7\u09a8\u0964',
                      ),
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: _guestNameController,
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: _text(
                          'Your name (optional)',
                          '\u0986\u09aa\u09a8\u09be\u09b0 \u09a8\u09be\u09ae (\u0985\u099a\u09cd\u099b\u09bf\u0995)',
                        ),
                        hintText: _text(
                          'e.g. Siam',
                          '\u09af\u09c7\u09ae\u09a8: \u09b8\u09bf\u09df\u09be\u09ae',
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    DropdownButtonFormField<AppLanguage>(
                      initialValue: language,
                      decoration: InputDecoration(
                        labelText: _text(
                          'Language',
                          '\u09ad\u09be\u09b7\u09be',
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AppLanguage.bangla,
                          child: Text('Bangla'),
                        ),
                        DropdownMenuItem(
                          value: AppLanguage.english,
                          child: Text('English'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => language = value);
                      },
                    ),
                    SizedBox(height: 4.h),
                    SwitchListTile(
                      value: prayerAlerts,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _text(
                          'Adhan / Prayer alert',
                          '\u0986\u09af\u09be\u09a8 / \u09a8\u09be\u09ae\u09be\u099c \u098f\u09b2\u09be\u09b0\u09cd\u099f',
                        ),
                      ),
                      subtitle: Text(
                        _text(
                          'Play prayer notifications',
                          '\u09a8\u09be\u09ae\u09be\u099c\u09c7\u09b0 \u09a8\u09cb\u099f\u09bf\u09ab\u09bf\u0995\u09c7\u09b6\u09a8 \u099a\u09be\u09b2\u09c1 \u09b0\u09be\u0996\u09c1\u09a8',
                        ),
                      ),
                      onChanged: (value) =>
                          setDialogState(() => prayerAlerts = value),
                    ),
                    SwitchListTile(
                      value: mealAlerts,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _text(
                          'Sehri / Iftar alert',
                          '\u09b8\u09c7\u09b9\u09b0\u09bf / \u0987\u09ab\u09a4\u09be\u09b0 \u098f\u09b2\u09be\u09b0\u09cd\u099f',
                        ),
                      ),
                      subtitle: Text(
                        _text(
                          'Meal time reminder notifications',
                          '\u0996\u09be\u09ac\u09be\u09b0\u09c7\u09b0 \u09b8\u09ae\u09df\u09c7\u09b0 \u09b0\u09bf\u09ae\u09be\u0987\u09a8\u09cd\u09a1\u09be\u09b0 \u09a8\u09cb\u099f\u09bf\u09ab\u09bf\u0995\u09c7\u09b6\u09a8',
                        ),
                      ),
                      onChanged: (value) =>
                          setDialogState(() => mealAlerts = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: Text(
                    _text('Cancel', '\u09ac\u09be\u09a4\u09bf\u09b2'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop((
                    name: '',
                    language: appLanguageNotifier.value,
                    prayerAlerts: prayerAlertsEnabledNotifier.value,
                    mealAlerts:
                        sehriAlertEnabledNotifier.value ||
                        iftarAlertEnabledNotifier.value,
                  )),
                  child: Text(_text('Skip', '\u09b8\u09cd\u0995\u09bf\u09aa')),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop((
                    name: _guestNameController.text.trim(),
                    language: language,
                    prayerAlerts: prayerAlerts,
                    mealAlerts: mealAlerts,
                  )),
                  child: Text(
                    _text(
                      'Continue',
                      '\u099a\u09be\u09b2\u09bf\u09df\u09c7 \u09af\u09be\u09a8',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    return result;
  }

  Future<void> _continueWithoutSignIn() async {
    final setup = await _promptGuestQuickSetup();
    if (setup == null) return;
    if (setup.name.trim().isNotEmpty) {
      profileNameNotifier.value = setup.name.trim();
    }
    appLanguageNotifier.value = setup.language;
    translationLanguageNotifier.value = setup.language == AppLanguage.bangla
        ? 'Bangla'
        : 'English';
    prayerAlertsEnabledNotifier.value = setup.prayerAlerts;
    sehriAlertEnabledNotifier.value = setup.mealAlerts;
    iftarAlertEnabledNotifier.value = setup.mealAlerts;
    await _setSkipAuthGate(true);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
  }

  Future<void> _signIn() async {
    if (!await _ensureInternetOrShowMessage()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        _text(
          'Please enter email and password.',
          '\u0987\u09ae\u0987\u09b2 \u098f\u09ac\u0982 \u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09a6\u09bf\u09a8\u0964',
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );
      await _setSkipAuthGate(false);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
    } on FirebaseAuthException catch (e) {
      _showMessage(AuthService.instance.messageForException(e));
    } catch (_) {
      _showMessage(
        _text(
          'Sign in failed. Please try again.',
          '\u09b8\u09be\u0987\u09a8 \u0987\u09a8 \u09ac\u09cd\u09af\u09b0\u09cd\u09a5 \u09b9\u09df\u09c7\u099b\u09c7\u0964 \u0986\u09ac\u09be\u09b0 \u099a\u09c7\u09b7\u09cd\u099f\u09be \u0995\u09b0\u09c1\u09a8\u0964',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!await _ensureInternetOrShowMessage()) return;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage(
        _text(
          'Enter your email first to reset password.',
          '\u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09b0\u09bf\u09b8\u09c7\u099f \u0995\u09b0\u09a4\u09c7 \u0986\u0997\u09c7 \u0987\u09ae\u0987\u09b2 \u09a6\u09bf\u09a8\u0964',
        ),
      );
      return;
    }

    try {
      await AuthService.instance.sendPasswordReset(email);
      _showMessage(
        _text(
          'Password reset email sent. Check your inbox.',
          '\u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09b0\u09bf\u09b8\u09c7\u099f \u0987\u09ae\u0987\u09b2 \u09aa\u09be\u09a0\u09be\u09a8\u09cb \u09b9\u09df\u09c7\u099b\u09c7\u0964 \u0987\u09a8\u09ac\u0995\u09cd\u09b8 \u099a\u09c7\u0995 \u0995\u09b0\u09c1\u09a8\u0964',
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(AuthService.instance.messageForException(e));
    } catch (_) {
      _showMessage(
        _text(
          'Failed to send reset email. Please try again.',
          '\u09b0\u09bf\u09b8\u09c7\u099f \u0987\u09ae\u0987\u09b2 \u09aa\u09be\u09a0\u09be\u09a8\u09cb \u09af\u09be\u09df\u09a8\u09bf\u0964 \u0986\u09ac\u09be\u09b0 \u099a\u09c7\u09b7\u09cd\u099f\u09be \u0995\u09b0\u09c1\u09a8\u0964',
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!await _ensureInternetOrShowMessage()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      await _setSkipAuthGate(false);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
    } on GoogleSignInException catch (e) {
      _showMessage(AuthService.instance.messageForGoogleException(e));
    } on FirebaseAuthException catch (e) {
      _showMessage(AuthService.instance.messageForException(e));
    } catch (_) {
      _showMessage(
        _text(
          'Google sign-in failed. Please try again.',
          '\u0997\u09c1\u0997\u09b2 \u09b8\u09be\u0987\u09a8 \u0987\u09a8 \u09ac\u09cd\u09af\u09b0\u09cd\u09a5 \u09b9\u09df\u09c7\u099b\u09c7\u0964 \u0986\u09ac\u09be\u09b0 \u099a\u09c7\u09b7\u09cd\u099f\u09be \u0995\u09b0\u09c1\u09a8\u0964',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: _authShell(
        context,
        NoorifyGlassCard(
          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
          radius: BorderRadius.circular(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _text('Sign In', '\u09b8\u09be\u0987\u09a8 \u0987\u09a8'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: glass.textPrimary,
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Center(
                child: SizedBox(
                  width: 80.w,
                  child: Divider(
                    color: glass.accent.withValues(alpha: 0.5),
                    thickness: 1,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: _fieldStyle(
                  glass,
                  label: _text('Email', '\u0987\u09ae\u0987\u09b2'),
                  hint: 'muslimah.gmail.com',
                  suffixIcon: Icon(
                    Icons.email_outlined,
                    color: glass.accentSoft,
                    size: 16.sp,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) {
                  if (_isLoading) return;
                  _signIn();
                },
                decoration: _fieldStyle(
                  glass,
                  label: _text(
                    'Password',
                    '\u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1',
                  ),
                  hint: '........',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: glass.accentSoft,
                      size: 16.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: glass.accentSoft,
                  ),
                  child: Text(
                    _text(
                      'Forgot Password?',
                      '\u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09ad\u09c1\u09b2\u09c7 \u0997\u09c7\u099b\u09c7\u09a8?',
                    ),
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              SizedBox(
                height: 42.h,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: glass.accent,
                    foregroundColor: glass.isDark
                        ? const Color(0xFF072734)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: glass.isDark
                                ? const Color(0xFF072734)
                                : Colors.white,
                          ),
                        )
                      : Text(
                          _text(
                            'SIGN IN',
                            '\u09b8\u09be\u0987\u09a8 \u0987\u09a8',
                          ),
                          style: TextStyle(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 14.h),
              _orDivider(glass),
              SizedBox(height: 14.h),
              SizedBox(
                height: 40.h,
                child: FilledButton.tonalIcon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: Icon(Icons.g_mobiledata, size: 20.sp),
                  label: Text(
                    _isLoading
                        ? _text(
                            'Please wait...',
                            '\u0985\u09aa\u09c7\u0995\u09cd\u09b7\u09be \u0995\u09b0\u09c1\u09a8...',
                          )
                        : _text(
                            'Continue With Google',
                            '\u0997\u09c1\u0997\u09b2 \u09a6\u09bf\u09df\u09c7 \u099a\u09be\u09b2\u09bf\u09df\u09c7 \u09af\u09be\u09a8',
                          ),
                  ),
                  style: FilledButton.styleFrom(
                    foregroundColor: glass.textPrimary,
                    backgroundColor: glass.isDark
                        ? const Color(0x332EB8E6)
                        : const Color(0x221EA8B8),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _text(
                      "Don't have any account? ",
                      '\u0985\u09cd\u09af\u09be\u0995\u09be\u0989\u09a8\u09cd\u099f \u09a8\u09c7\u0987? ',
                    ),
                    style: TextStyle(color: glass.textSecondary, fontSize: 12.sp),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteNames.signUp),
                    child: Text(
                      _text(
                        'Register',
                        '\u09b0\u09c7\u099c\u09bf\u09b8\u09cd\u099f\u09be\u09b0',
                      ),
                      style: TextStyle(
                        color: glass.accent,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: _isLoading ? null : _continueWithoutSignIn,
                child: Text(
                  _text(
                    'Skip for now',
                    '\u098f\u0996\u09a8 \u09b8\u09cd\u0995\u09bf\u09aa \u0995\u09b0\u09c1\u09a8',
                  ),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
