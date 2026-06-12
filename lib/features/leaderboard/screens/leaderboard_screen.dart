import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/family/widgets/add_family_dialog.dart';
import 'package:first_project/features/leaderboard/models/leaderboard_entry.dart';
import 'package:first_project/features/leaderboard/services/leaderboard_service.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isBangla =
        context.watch<LanguageProvider>().current == AppLanguage.bangla;
    final glass = NoorifyGlassTheme(context);
    String t(String en, String bn) => isBangla ? bn : en;
    final me = LeaderboardService.instance.currentUid;

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                          t('Leaderboard', 'লিডারবোর্ড'),
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: glass.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      t(
                        'Top members by points earned',
                        'পয়েন্টের ভিত্তিতে শীর্ষ সদস্যরা',
                      ),
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        color: glass.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<LeaderboardEntry>>(
                  stream: LeaderboardService.instance.watchLeaderboard(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: glass.accent),
                      );
                    }
                    if (snapshot.hasError) {
                      return _CenterMessage(
                        glass: glass,
                        icon: Icons.error_outline_rounded,
                        text: t(
                          'Could not load leaderboard',
                          'লিডারবোর্ড লোড করা যায়নি',
                        ),
                      );
                    }

                    final entries =
                        snapshot.data ?? const <LeaderboardEntry>[];
                    if (entries.isEmpty) {
                      return _CenterMessage(
                        glass: glass,
                        icon: Icons.emoji_events_outlined,
                        text: t('No members yet', 'এখনো কোনো সদস্য নেই'),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 14.h),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final isMe = entry.uid == me;
                        return _LeaderboardTile(
                          glass: glass,
                          rank: index + 1,
                          entry: entry,
                          isMe: isMe,
                          pointsLabel: t('pts', 'পয়েন্ট'),
                          onTap: isMe
                              ? null
                              : () => AddFamilyDialog.show(
                                  context,
                                  targetUid: entry.uid,
                                  targetName: entry.resolvedName,
                                  targetPhoto: entry.photoUrl,
                                  targetEmail: entry.email,
                                  isBangla: isBangla,
                                ),
                        );
                      },
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

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.glass,
    required this.rank,
    required this.entry,
    required this.isMe,
    required this.pointsLabel,
    this.onTap,
  });

  final NoorifyGlassTheme glass;
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  final String pointsLabel;
  final VoidCallback? onTap;

  /// Medal colours for the top three ranks; null for the rest.
  Color? get _medalColor {
    switch (rank) {
      case 1:
        return const Color(0xFFE6B422); // gold
      case 2:
        return const Color(0xFF9AA7B2); // silver
      case 3:
        return const Color(0xFFC17A4A); // bronze
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final medal = _medalColor;

    return NoorifyGlassCard(
      radius: BorderRadius.circular(16.r),
      padding: EdgeInsets.zero,
      child: Container(
        decoration: isMe
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: glass.accent.withValues(alpha: 0.6),
                  width: 1.4,
                ),
              )
            : null,
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26.w,
                child: medal != null
                    ? Icon(Icons.emoji_events_rounded, color: medal, size: 22.r)
                    : Text(
                        '$rank',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: glass.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                        ),
                      ),
              ),
              SizedBox(width: 8.w),
              CircleAvatar(
                radius: 22.r,
                backgroundColor: glass.accent.withValues(alpha: 0.18),
                backgroundImage: entry.photoUrl != null
                    ? NetworkImage(entry.photoUrl!)
                    : null,
                child: entry.photoUrl == null
                    ? Text(
                        entry.initial,
                        style: TextStyle(
                          color: glass.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 17.sp,
                        ),
                      )
                    : null,
              ),
            ],
          ),
          title: Text(
            isMe ? '${entry.resolvedName} (You)' : entry.resolvedName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: glass.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15.sp,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
                style: TextStyle(
                  color: glass.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 17.sp,
                ),
              ),
              Text(
                pointsLabel,
                style: TextStyle(
                  color: glass.textMuted,
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({
    required this.glass,
    required this.icon,
    required this.text,
  });

  final NoorifyGlassTheme glass;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46.r, color: glass.textMuted),
          SizedBox(height: 10.h),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: glass.textSecondary, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
