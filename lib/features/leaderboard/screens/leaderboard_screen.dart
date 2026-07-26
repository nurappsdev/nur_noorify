import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/family/models/family_member.dart';
import 'package:first_project/features/family/services/family_service.dart';
import 'package:first_project/features/leaderboard/models/leaderboard_entry.dart';
import 'package:first_project/features/leaderboard/services/leaderboard_service.dart';
import 'package:first_project/features/quran/widgets/quran_list_widgets.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

enum _LeaderboardScope { global, family }

enum _LeaderboardPeriod { all, month, year }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  _LeaderboardScope _scope = _LeaderboardScope.global;
  _LeaderboardPeriod _period = _LeaderboardPeriod.all;

  /// Members are filtered by *join date* falling in the selected period —
  /// points themselves are a lifetime running total with no award history,
  /// so this can't filter "points earned in period", only "who joined when".
  bool _inPeriod(DateTime? createdAt) {
    if (_period == _LeaderboardPeriod.all) return true;
    if (createdAt == null) return false;
    final now = DateTime.now();
    if (_period == _LeaderboardPeriod.year) return createdAt.year == now.year;
    return createdAt.year == now.year && createdAt.month == now.month;
  }

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
                        Expanded(
                          child: Text(
                            t('Leaderboard', 'লিডারবোর্ড'),
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: glass.textPrimary,
                            ),
                          ),
                        ),
                        FilterChipButton(
                          label: t('Global', 'গ্লোবাল'),
                          selected: _scope == _LeaderboardScope.global,
                          onTap: () =>
                              setState(() => _scope = _LeaderboardScope.global),
                        ),
                        SizedBox(width: 6.w),
                        FilterChipButton(
                          label: t('Family', 'পরিবার'),
                          selected: _scope == _LeaderboardScope.family,
                          onTap: () =>
                              setState(() => _scope = _LeaderboardScope.family),
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
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(5.r),
                      decoration: BoxDecoration(
                        color: glass.isDark
                            ? const Color(0x3816232F)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: glass.isDark
                              ? const Color(0x6AA9C7DB)
                              : const Color(0x88D1E1EC),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilterChipButton(
                              label: t('All time', 'সব সময়'),
                              selected: _period == _LeaderboardPeriod.all,
                              isSegment: true,
                              onTap: () => setState(
                                () => _period = _LeaderboardPeriod.all,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: FilterChipButton(
                              label: t('This Month', 'এই মাস'),
                              selected: _period == _LeaderboardPeriod.month,
                              isSegment: true,
                              onTap: () => setState(
                                () => _period = _LeaderboardPeriod.month,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: FilterChipButton(
                              label: t('This Year', 'এই বছর'),
                              selected: _period == _LeaderboardPeriod.year,
                              isSegment: true,
                              onTap: () => setState(
                                () => _period = _LeaderboardPeriod.year,
                              ),
                            ),
                          ),
                        ],
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

                    final allEntries = (snapshot.data ?? const <LeaderboardEntry>[])
                        .where((entry) => _inPeriod(entry.createdAt))
                        .toList();

                    String emptyTextFor(String allTime, String month, String year) {
                      switch (_period) {
                        case _LeaderboardPeriod.month:
                          return month;
                        case _LeaderboardPeriod.year:
                          return year;
                        case _LeaderboardPeriod.all:
                          return allTime;
                      }
                    }

                    if (_scope == _LeaderboardScope.global) {
                      return _LeaderboardList(
                        glass: glass,
                        entries: allEntries,
                        me: me,
                        t: t,
                        emptyText: emptyTextFor(
                          t('No members yet', 'এখনো কোনো সদস্য নেই'),
                          t(
                            'No members joined this month',
                            'এই মাসে কোনো সদস্য যোগ দেননি',
                          ),
                          t(
                            'No members joined this year',
                            'এই বছর কোনো সদস্য যোগ দেননি',
                          ),
                        ),
                      );
                    }

                    return StreamBuilder<List<FamilyMember>>(
                      stream: FamilyService.instance.watchFamilyMembers(),
                      builder: (context, familySnapshot) {
                        final familyUids = <String>{
                          ?me,
                          ...(familySnapshot.data ?? const <FamilyMember>[])
                              .map((member) => member.uid),
                        };
                        final entries = allEntries
                            .where((entry) => familyUids.contains(entry.uid))
                            .toList();

                        return _LeaderboardList(
                          glass: glass,
                          entries: entries,
                          me: me,
                          t: t,
                          emptyText: emptyTextFor(
                            t(
                              'No family members yet',
                              'এখনো কোনো পরিবারের সদস্য নেই',
                            ),
                            t(
                              'No family members joined this month',
                              'এই মাসে পরিবারের কোনো সদস্য যোগ দেননি',
                            ),
                            t(
                              'No family members joined this year',
                              'এই বছর পরিবারের কোনো সদস্য যোগ দেননি',
                            ),
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

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({
    required this.glass,
    required this.entries,
    required this.me,
    required this.t,
    required this.emptyText,
  });

  final NoorifyGlassTheme glass;
  final List<LeaderboardEntry> entries;
  final String? me;
  final String Function(String en, String bn) t;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _CenterMessage(
        glass: glass,
        icon: Icons.emoji_events_outlined,
        text: emptyText,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 14.h),
      itemCount: entries.length,
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _LeaderboardTile(
          glass: glass,
          rank: index + 1,
          entry: entry,
          isMe: entry.uid == me,
          pointsLabel: t('pts', 'পয়েন্ট'),
        );
      },
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
  });

  final NoorifyGlassTheme glass;
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  final String pointsLabel;

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
