import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/features/auth/services/auth_service.dart';

/// Shows the change-password dialog. Returns true when the password was
/// successfully updated.
Future<bool?> showChangePasswordDialog(
  BuildContext context, {
  required String Function(String english, String bangla) text,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => _ChangePasswordDialog(text: text),
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.text});

  final String Function(String english, String bangla) text;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var obscureCurrent = true;
  var obscureNew = true;
  var obscureConfirm = true;
  var submitting = false;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final current = currentPasswordController.text;
    final next = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      _snack('Please complete all fields.');
      return;
    }
    if (next.length < 6) {
      _snack('New password must be at least 6 characters.');
      return;
    }
    if (next != confirm) {
      _snack('New password and confirm password do not match.');
      return;
    }
    if (current == next) {
      _snack('New password must be different from current password.');
      return;
    }

    setState(() => submitting = true);
    try {
      await AuthService.instance.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      _snack(AuthService.instance.messageForException(e));
    } catch (_) {
      _snack('Failed to change password. Please try again.');
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.text(
          'Change Password',
          '\u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09aa\u09b0\u09bf\u09ac\u09b0\u09cd\u09a4\u09a8',
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: currentPasswordController,
            obscureText: obscureCurrent,
            decoration: InputDecoration(
              labelText: widget.text(
                'Current Password',
                '\u09ac\u09b0\u09cd\u09a4\u09ae\u09be\u09a8 \u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1',
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => obscureCurrent = !obscureCurrent);
                },
                icon: Icon(
                  obscureCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: newPasswordController,
            obscureText: obscureNew,
            decoration: InputDecoration(
              labelText: widget.text(
                'New Password',
                '\u09a8\u09a4\u09c1\u09a8 \u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1',
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => obscureNew = !obscureNew);
                },
                icon: Icon(
                  obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: confirmPasswordController,
            obscureText: obscureConfirm,
            decoration: InputDecoration(
              labelText: widget.text(
                'Confirm Password',
                '\u09aa\u09be\u09b8\u0993\u09df\u09be\u09b0\u09cd\u09a1 \u09a8\u09bf\u09b6\u09cd\u099a\u09bf\u09a4 \u0995\u09b0\u09c1\u09a8',
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => obscureConfirm = !obscureConfirm);
                },
                icon: Icon(
                  obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: submitting ? null : () => Navigator.of(context).pop(false),
          child: Text(widget.text('Cancel', '\u09ac\u09be\u09a4\u09bf\u09b2')),
        ),
        FilledButton(
          onPressed: submitting ? null : _submit,
          child: submitting
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.text('Update', '\u0986\u09aa\u09a1\u09c7\u099f')),
        ),
      ],
    );
  }
}
