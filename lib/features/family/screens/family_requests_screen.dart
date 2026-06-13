import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/family/models/family_relation.dart';
import 'package:first_project/features/family/models/family_request.dart';
import 'package:first_project/features/family/services/family_service.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

/// Inbox of incoming family requests. The recipient accepts or declines here;
/// accepting flips the request status, after which the Cloud Function adds the
/// recipient to the requester's family list.
class FamilyRequestsScreen extends StatelessWidget {
  const FamilyRequestsScreen({super.key});

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
                      t('Family Requests', 'পরিবারের অনুরোধ'),
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: glass.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<FamilyRequest>>(
                  stream: FamilyService.instance.watchIncomingRequests(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: glass.accent),
                      );
                    }
                    final requests =
                        snapshot.data ?? const <FamilyRequest>[];
                    if (requests.isEmpty) {
                      return _EmptyState(glass: glass, t: t);
                    }
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 14.h),
                      itemCount: requests.length,
                      separatorBuilder: (_, _) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) => _RequestTile(
                        glass: glass,
                        request: requests[index],
                        isBangla: isBangla,
                        t: t,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.glass,
    required this.request,
    required this.isBangla,
    required this.t,
  });

  final NoorifyGlassTheme glass;
  final FamilyRequest request;
  final bool isBangla;
  final String Function(String, String) t;

  /// Names the relationship the requester chose ("wants to add you as their
  /// father"), falling back to the generic line for requests saved before
  /// relationships were stored.
  String _subtitle() {
    final relation = request.relation;
    if (relation == null) {
      return t('wants to add you as family', 'আপনাকে পরিবারে যোগ করতে চায়');
    }
    final label = relation.label(isBangla);
    return t(
      'wants to add you as their ${label.toLowerCase()}',
      'আপনাকে তাদের $label হিসেবে যোগ করতে চায়',
    );
  }

  @override
  Widget build(BuildContext context) {
    return NoorifyGlassCard(
      radius: BorderRadius.circular(16.r),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: glass.accent.withValues(alpha: 0.18),
            backgroundImage: request.fromPhoto != null
                ? NetworkImage(request.fromPhoto!)
                : null,
            child: request.fromPhoto == null
                ? Text(
                    request.fromInitial,
                    style: TextStyle(
                      color: glass.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 17.sp,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.resolvedFromName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: glass.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _subtitle(),
                  style: TextStyle(
                    color: glass.textSecondary,
                    fontSize: 11.5.sp,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: t('Decline', 'প্রত্যাখ্যান'),
            onPressed: () => FamilyService.instance.decline(request),
            icon: Icon(Icons.close_rounded, color: glass.textMuted, size: 22.r),
          ),
          IconButton(
            tooltip: t('Accept', 'গ্রহণ'),
            onPressed: () => FamilyService.instance.accept(request),
            icon: Icon(
              Icons.check_circle_rounded,
              color: glass.accent,
              size: 26.r,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.glass, required this.t});

  final NoorifyGlassTheme glass;
  final String Function(String, String) t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_outlined, size: 46.r, color: glass.textMuted),
          SizedBox(height: 10.h),
          Text(
            t('No pending requests', 'কোনো অপেক্ষমাণ অনুরোধ নেই'),
            style: TextStyle(color: glass.textSecondary, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
