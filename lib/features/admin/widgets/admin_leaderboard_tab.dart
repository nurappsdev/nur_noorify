import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/features/admin/models/points_history_entry.dart';
import 'package:first_project/features/admin/models/quiz_attempt_record.dart';
import 'package:first_project/features/admin/services/admin_role_service.dart';
import 'package:first_project/features/admin/services/leaderboard_admin_service.dart';
import 'package:first_project/features/leaderboard/models/leaderboard_entry.dart';
import 'package:first_project/features/quran/widgets/quran_list_widgets.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

enum _LbSection { rankings, history, quiz }

String _formatDateTime(DateTime? value) {
  if (value == null) return 'pending';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}

/// Resolves a display name for [uid] out of the `users/{uid}` docs, falling
/// back to email then the uid itself.
String _nameFor(
  Map<String, Map<String, dynamic>> usersById,
  String uid,
) {
  final data = usersById[uid];
  if (data == null) return uid;
  final name = (data['display_name'] ?? '').toString().trim();
  if (name.isNotEmpty) return name;
  final email = (data['email'] ?? '').toString().trim();
  if (email.isNotEmpty) return email;
  return uid;
}

/// Admin panel tab: leaderboard rankings, the point-earning history log, and
/// Elm Noor quiz performance — everything an admin needs to monitor how
/// members are earning points and engaging with quizzes.
class AdminLeaderboardTab extends StatefulWidget {
  const AdminLeaderboardTab({super.key});

  @override
  State<AdminLeaderboardTab> createState() => _AdminLeaderboardTabState();
}

class _AdminLeaderboardTabState extends State<AdminLeaderboardTab> {
  _LbSection _section = _LbSection.rankings;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 6.h),
          child: Container(
            padding: EdgeInsets.all(5.r),
            decoration: BoxDecoration(
              color: glass.isDark ? const Color(0x3816232F) : Colors.white,
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
                    label: 'Rankings',
                    selected: _section == _LbSection.rankings,
                    isSegment: true,
                    onTap: () => setState(() => _section = _LbSection.rankings),
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: FilterChipButton(
                    label: 'History',
                    selected: _section == _LbSection.history,
                    isSegment: true,
                    onTap: () => setState(() => _section = _LbSection.history),
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: FilterChipButton(
                    label: 'Quiz Stats',
                    selected: _section == _LbSection.quiz,
                    isSegment: true,
                    onTap: () => setState(() => _section = _LbSection.quiz),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: switch (_section) {
            _LbSection.rankings => const _RankingsView(),
            _LbSection.history => const _PointsHistoryView(),
            _LbSection.quiz => const _QuizPerformanceView(),
          },
        ),
      ],
    );
  }
}

class _RankingsView extends StatelessWidget {
  const _RankingsView();

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return StreamBuilder<List<LeaderboardEntry>>(
      stream: LeaderboardAdminService.instance.watchRankings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data ?? const <LeaderboardEntry>[];
        if (entries.isEmpty) {
          return const Center(child: Text('No members yet.'));
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 90.h),
          itemCount: entries.length,
          separatorBuilder: (_, _) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return NoorifyGlassCard(
              radius: BorderRadius.circular(14.r),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 26.w,
                    child: Text(
                      '${index + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: glass.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  CircleAvatar(
                    radius: 18.r,
                    backgroundImage: entry.photoUrl != null
                        ? NetworkImage(entry.photoUrl!)
                        : null,
                    child: entry.photoUrl == null
                        ? Text(entry.initial)
                        : null,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.resolvedName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                            color: glass.textPrimary,
                          ),
                        ),
                        if (entry.email.isNotEmpty)
                          Text(
                            entry.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: glass.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${entry.points} pts',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: glass.accent,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PointsHistoryView extends StatelessWidget {
  const _PointsHistoryView();

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AdminRoleService.instance.watchAllUsers(),
      builder: (context, usersSnapshot) {
        final Map<String, Map<String, dynamic>> usersById = {
          for (final doc in usersSnapshot.data?.docs ?? const [])
            doc.id: doc.data(),
        };

        return StreamBuilder<List<PointsHistoryEntry>>(
          stream: LeaderboardAdminService.instance.watchPointsHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final events = snapshot.data ?? const <PointsHistoryEntry>[];
            if (events.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No point-earning events logged yet.\nThey will appear here as members earn points.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 90.h),
              itemCount: events.length,
              separatorBuilder: (_, _) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final event = events[index];
                return NoorifyGlassCard(
                  radius: BorderRadius.circular(14.r),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameFor(usersById, event.uid),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                                color: glass.textPrimary,
                              ),
                            ),
                            Text(
                              '${event.sourceLabel} • ${_formatDateTime(event.createdAt)}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: glass.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${event.amount}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: glass.accent,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _QuizPerformanceView extends StatelessWidget {
  const _QuizPerformanceView();

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AdminRoleService.instance.watchAllUsers(),
      builder: (context, usersSnapshot) {
        final Map<String, Map<String, dynamic>> usersById = {
          for (final doc in usersSnapshot.data?.docs ?? const [])
            doc.id: doc.data(),
        };

        return StreamBuilder<List<QuizAttemptRecord>>(
          stream: LeaderboardAdminService.instance.watchQuizAttempts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final attempts = snapshot.data ?? const <QuizAttemptRecord>[];
            if (attempts.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No quiz attempts logged yet.\nThey will appear here once members play Elm Noor.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final totalAttempts = attempts.length;
            final avgAccuracy =
                attempts.map((a) => a.accuracy).reduce((a, b) => a + b) /
                totalAttempts;

            final byTopic = <String, List<QuizAttemptRecord>>{};
            for (final a in attempts) {
              byTopic.putIfAbsent(a.topic, () => []).add(a);
            }

            return ListView(
              padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 90.h),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        glass,
                        label: 'Total attempts',
                        value: '$totalAttempts',
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _statCard(
                        glass,
                        label: 'Avg. accuracy',
                        value: '${(avgAccuracy * 100).round()}%',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  'By topic',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                    color: glass.textPrimary,
                  ),
                ),
                SizedBox(height: 6.h),
                ...byTopic.entries.map((entry) {
                  final topicAttempts = entry.value;
                  final topicAvg =
                      topicAttempts
                          .map((a) => a.accuracy)
                          .reduce((a, b) => a + b) /
                      topicAttempts.length;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: NoorifyGlassCard(
                      radius: BorderRadius.circular(14.r),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: glass.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${topicAttempts.length} attempts • ${(topicAvg * 100).round()}% avg',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: glass.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: 6.h),
                Text(
                  'Recent attempts',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                    color: glass.textPrimary,
                  ),
                ),
                SizedBox(height: 6.h),
                ...attempts.take(50).map((attempt) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: NoorifyGlassCard(
                      radius: BorderRadius.circular(14.r),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameFor(usersById, attempt.uid),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.sp,
                                    color: glass.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${attempt.topic} • ${_formatDateTime(attempt.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: glass.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${attempt.correct}/${attempt.total}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: glass.accent,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(
    NoorifyGlassTheme glass, {
    required String label,
    required String value,
  }) {
    return NoorifyGlassCard(
      radius: BorderRadius.circular(14.r),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: glass.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: glass.textMuted),
          ),
        ],
      ),
    );
  }
}
