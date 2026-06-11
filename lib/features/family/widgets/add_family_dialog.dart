import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/features/family/services/family_service.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

/// Confirmation dialog shown when a user taps another member on the
/// leaderboard. Submitting sends a pending family request (the name only
/// appears on the requester's profile after the other person accepts).
class AddFamilyDialog extends StatefulWidget {
  const AddFamilyDialog({
    super.key,
    required this.targetUid,
    required this.targetName,
    required this.targetPhoto,
    required this.isBangla,
  });

  final String targetUid;
  final String targetName;
  final String? targetPhoto;
  final bool isBangla;

  /// Opens the dialog. Returns nothing; feedback is shown via SnackBar.
  static Future<void> show(
    BuildContext context, {
    required String targetUid,
    required String targetName,
    String? targetPhoto,
    required bool isBangla,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AddFamilyDialog(
        targetUid: targetUid,
        targetName: targetName,
        targetPhoto: targetPhoto,
        isBangla: isBangla,
      ),
    );
  }

  @override
  State<AddFamilyDialog> createState() => _AddFamilyDialogState();
}

class _AddFamilyDialogState extends State<AddFamilyDialog> {
  bool _submitting = false;

  String t(String en, String bn) => widget.isBangla ? bn : en;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final result = await FamilyService.instance.sendRequest(
      toUid: widget.targetUid,
      toName: widget.targetName,
      toPhoto: widget.targetPhoto,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    _showResult(result);
  }

  void _showResult(SendRequestResult result) {
    final messenger = ScaffoldMessenger.of(context);
    final String message;
    switch (result) {
      case SendRequestResult.sent:
        message = t(
          'Request sent to ${widget.targetName}',
          '${widget.targetName} কে অনুরোধ পাঠানো হয়েছে',
        );
        break;
      case SendRequestResult.alreadyRequested:
        message = t('Request already pending', 'অনুরোধ ইতিমধ্যে অপেক্ষমাণ');
        break;
      case SendRequestResult.alreadyFamily:
        message = t('Already a family member', 'ইতিমধ্যে পরিবারের সদস্য');
        break;
      case SendRequestResult.selfRequest:
        message = t('You cannot add yourself', 'আপনি নিজেকে যোগ করতে পারবেন না');
        break;
      case SendRequestResult.notSignedIn:
        message = t('Please sign in first', 'প্রথমে সাইন ইন করুন');
        break;
      case SendRequestResult.error:
        message = t('Could not send request', 'অনুরোধ পাঠানো যায়নি');
        break;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Dialog(
      backgroundColor: glass.bgBottom,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.group_add_rounded,
                  color: glass.accent,
                  size: 22.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    t('Add family member', 'পরিবারের সদস্য যোগ করুন'),
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: glass.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              t(
                'Send a family request to ${widget.targetName}. They will appear on your profile once they accept.',
                '${widget.targetName} কে পরিবারের অনুরোধ পাঠান। তারা গ্রহণ করলে আপনার প্রোফাইলে দেখা যাবে।',
              ),
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.4,
                color: glass.textSecondary,
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    t('Cancel', 'বাতিল'),
                    style: TextStyle(color: glass.textSecondary),
                  ),
                ),
                SizedBox(width: 6.w),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: glass.accent),
                  child: _submitting
                      ? SizedBox(
                          width: 18.r,
                          height: 18.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(t('Submit Request', 'অনুরোধ পাঠান')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
