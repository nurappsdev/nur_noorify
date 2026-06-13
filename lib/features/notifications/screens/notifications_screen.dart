import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/family/models/family_request.dart';
import 'package:first_project/features/family/services/family_service.dart';
import 'package:first_project/features/notifications/widgets/notification_widgets.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

/// Notifications hub. Two groups:
///  * incoming family requests addressed to the user, which they can accept or
///    decline in place;
///  * the requests the user has sent, shown read-only with their status.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isBangla =
        context.watch<LanguageProvider>().current == AppLanguage.bangla;
    final glass = NoorifyGlassTheme(context);
    String t(String en, String bn) => isBangla ? bn : en;

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 6.h),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      Padding(
                        padding: EdgeInsets.only(right: 6.w),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20.r),
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: glass.textPrimary,
                            size: 24.r,
                          ),
                        ),
                      ),
                    Text(
                      t('Notifications', 'নোটিফিকেশন'),
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: glass.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _Body(glass: glass, isBangla: isBangla, t: t)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.glass, required this.isBangla, required this.t});

  final NoorifyGlassTheme glass;
  final bool isBangla;
  final Translate t;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FamilyRequest>>(
      stream: FamilyService.instance.watchIncomingRequests(),
      builder: (context, incomingSnap) {
        return StreamBuilder<List<FamilyRequest>>(
          stream: FamilyService.instance.watchOutgoingRequests(),
          builder: (context, outgoingSnap) {
            final incoming = incomingSnap.data ?? const <FamilyRequest>[];
            final outgoing = outgoingSnap.data ?? const <FamilyRequest>[];

            final loading =
                incomingSnap.connectionState == ConnectionState.waiting &&
                outgoingSnap.connectionState == ConnectionState.waiting;
            if (loading) {
              return Center(
                child: CircularProgressIndicator(color: glass.accent),
              );
            }

            return RefreshIndicator(
              color: glass.accent,
              onRefresh: FamilyService.instance.refreshFamilyData,
              child: (incoming.isEmpty && outgoing.isEmpty)
                  ? _PullableEmpty(glass: glass, t: t)
                  : _content(incoming, outgoing),
            );
          },
        );
      },
    );
  }

  Widget _content(List<FamilyRequest> incoming, List<FamilyRequest> outgoing) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
      children: [
        if (incoming.isNotEmpty) ...[
          NotificationSectionLabel(
            glass: glass,
            text: t('Requests to you', 'আপনাtর কাছে অনুরোধ'),
          ),
          for (final r in incoming)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: IncomingRequestTile(
                glass: glass,
                request: r,
                isBangla: isBangla,
                t: t,
              ),
            ),
        ],
        if (outgoing.isNotEmpty) ...[
          NotificationSectionLabel(
            glass: glass,
            text: t('Sent by you', 'আপনার পাঠানো'),
          ),
          for (final r in outgoing)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: FamilyNotificationTile(
                glass: glass,
                request: r,
                isBangla: isBangla,
                t: t,
              ),
            ),
        ],
      ],
    );
  }
}

/// Empty state that still scrolls, so pull-to-refresh works with no items.
class _PullableEmpty extends StatelessWidget {
  const _PullableEmpty({required this.glass, required this.t});

  final NoorifyGlassTheme glass;
  final Translate t;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: NotificationsEmptyState(glass: glass, t: t),
          ),
        );
      },
    );
  }
}
