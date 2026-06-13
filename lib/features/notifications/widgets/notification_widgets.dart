import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/features/family/models/family_relation.dart';
import 'package:first_project/features/family/models/family_request.dart';
import 'package:first_project/features/family/services/family_service.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

/// Bilingual text resolver shared by the notification widgets.
typedef Translate = String Function(String en, String bn);

/// Small uppercase-ish section heading above a group of notifications.
class NotificationSectionLabel extends StatelessWidget {
  const NotificationSectionLabel({super.key, required this.glass, required this.text});

  final NoorifyGlassTheme glass;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 12.h, 4.w, 6.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: glass.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Color-coded pill showing a request's status.
class NotificationStatusPill extends StatelessWidget {
  const NotificationStatusPill({super.key, required this.status, required this.t});

  final FamilyRequestStatus status;
  final Translate t;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    switch (status) {
      case FamilyRequestStatus.accepted:
        color = const Color(0xFF2E9E5B);
        label = t('Accepted', 'গৃহীত');
        break;
      case FamilyRequestStatus.declined:
        color = const Color(0xFFE5484D);
        label = t('Declined', 'প্রত্যাখ্যাত');
        break;
      case FamilyRequestStatus.pending:
        color = const Color(0xFFD9821B);
        label = t('Pending', 'অপেক্ষমাণ');
        break;
      case FamilyRequestStatus.unknown:
        color = const Color(0xFF8A8A8A);
        label = t('Unknown', 'অজানা');
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// A request the user *sent* — read-only, just name + relation/email + status.
class FamilyNotificationTile extends StatelessWidget {
  const FamilyNotificationTile({
    super.key,
    required this.glass,
    required this.request,
    required this.isBangla,
    required this.t,
  });

  final NoorifyGlassTheme glass;
  final FamilyRequest request;
  final bool isBangla;
  final Translate t;

  @override
  Widget build(BuildContext context) {
    final name = request.toName.trim().isEmpty
        ? t('Noorify user', 'নূরিফাই ব্যবহারকারী')
        : request.toName.trim();
    final subtitle = [
      if (request.relation != null) request.relation!.label(isBangla),
      if (request.toEmail != null) request.toEmail!,
    ].join(' · ');

    return NoorifyGlassCard(
      radius: BorderRadius.circular(16.r),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          _Avatar(glass: glass, name: name, photo: request.toPhoto),
          SizedBox(width: 10.w),
          Expanded(
            child: _NameAndSubtitle(glass: glass, name: name, subtitle: subtitle),
          ),
          SizedBox(width: 8.w),
          NotificationStatusPill(status: request.status, t: t),
        ],
      ),
    );
  }
}

/// A request *sent to* the user — actionable, with accept / decline.
class IncomingRequestTile extends StatefulWidget {
  const IncomingRequestTile({
    super.key,
    required this.glass,
    required this.request,
    required this.isBangla,
    required this.t,
  });

  final NoorifyGlassTheme glass;
  final FamilyRequest request;
  final bool isBangla;
  final Translate t;

  @override
  State<IncomingRequestTile> createState() => _IncomingRequestTileState();
}

class _IncomingRequestTileState extends State<IncomingRequestTile> {
  bool _busy = false;

  Future<void> _respond(Future<void> Function(FamilyRequest) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    await action(widget.request);
    // The stream drops this request once handled, so the tile is removed; only
    // restore state if we somehow remain mounted (e.g. a write error).
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final glass = widget.glass;
    final request = widget.request;
    final name = request.resolvedFromName;
    final relation = request.relation;
    final subtitle = relation == null
        ? widget.t('wants to add you as family', 'আপনাকে পরিবারে যোগ করতে চায়')
        : widget.t(
            'wants to add you as ${relation.label(false)}',
            '${relation.label(true)} হিসেবে যোগ করতে চায়',
          );

    return NoorifyGlassCard(
      radius: BorderRadius.circular(16.r),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(glass: glass, name: name, photo: request.fromPhoto),
              SizedBox(width: 10.w),
              Expanded(
                child: _NameAndSubtitle(
                  glass: glass,
                  name: name,
                  subtitle: subtitle,
                ),
              ),
              SizedBox(width: 8.w),
              NotificationStatusPill(status: request.status, t: widget.t),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _respond(FamilyService.instance.decline),
                style: TextButton.styleFrom(foregroundColor: glass.textMuted),
                child: Text(widget.t('Decline', 'প্রত্যাখ্যান')),
              ),
              SizedBox(width: 6.w),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _respond(FamilyService.instance.accept),
                style: FilledButton.styleFrom(backgroundColor: glass.accent),
                child: _busy
                    ? SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.t('Accept', 'গ্রহণ')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.glass, required this.name, required this.photo});

  final NoorifyGlassTheme glass;
  final String name;
  final String? photo;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20.r,
      backgroundColor: glass.accent.withValues(alpha: 0.18),
      backgroundImage: photo != null ? NetworkImage(photo!) : null,
      child: photo == null
          ? Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: TextStyle(
                color: glass.accent,
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
              ),
            )
          : null,
    );
  }
}

class _NameAndSubtitle extends StatelessWidget {
  const _NameAndSubtitle({
    required this.glass,
    required this.name,
    required this.subtitle,
  });

  final NoorifyGlassTheme glass;
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: glass.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: glass.textSecondary, fontSize: 11.5.sp),
          ),
        ],
      ],
    );
  }
}

/// Shown when there are no incoming or sent requests at all.
class NotificationsEmptyState extends StatelessWidget {
  const NotificationsEmptyState({super.key, required this.glass, required this.t});

  final NoorifyGlassTheme glass;
  final Translate t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 46.r,
            color: glass.textMuted,
          ),
          SizedBox(height: 10.h),
          Text(
            t('No notifications yet', 'এখনো কোনো নোটিফিকেশন নেই'),
            style: TextStyle(color: glass.textSecondary, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
