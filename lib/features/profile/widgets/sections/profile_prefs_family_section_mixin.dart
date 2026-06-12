part of '../../screens/profile_preferences_screen.dart';

/// Profile section that lists the user's accepted family members and links to
/// the incoming family-request inbox (with an unread badge).
mixin ProfilePrefsFamilySectionMixin
    on
        State<ProfilePreferencesScreen>,
        ProfilePrefsStateMixin,
        ProfilePrefsUiMixin {
  List<Widget> _buildFamilySection() {
    final glass = NoorifyGlassTheme(context);
    return [
      _sectionLabel(_text('Family', 'পরিবার')),
      _sectionCard(
        child: StreamBuilder<List<FamilyMember>>(
          stream: FamilyService.instance.watchFamilyMembers(),
          builder: (context, snapshot) {
            final members = snapshot.data ?? const <FamilyMember>[];
            if (members.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
                child: Text(
                  _text('No family members yet', 'এখনো কোনো পরিবারের সদস্য নেই'),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: glass.textSecondary,
                  ),
                ),
              );
            }
            return Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: members
                  .map((m) => _familyChip(glass, m))
                  .toList(),
            );
          },
        ),
      ),
      ..._buildIncomingRequests(),
      ..._buildSentRequests(),
      _sectionCard(
        child: StreamBuilder<int>(
          stream: FamilyService.instance.watchIncomingCount(),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return _rowTile(
              icon: Icons.group_add_rounded,
              title: _text('Family Requests', 'পরিবারের অনুরোধ'),
              subtitle: _text(
                'Review who wants to add you',
                'কে আপনাকে যোগ করতে চায় দেখুন',
              ),
              trailing: count > 0 ? _badge(count) : null,
              onTap: () => Navigator.of(
                context,
              ).pushNamed(RouteNames.familyRequests),
            );
          },
        ),
      ),
    ];
  }

  /// Inline list of pending requests addressed to the user, with accept /
  /// decline actions right on the profile. Hidden while there are none.
  List<Widget> _buildIncomingRequests() {
    return [
      StreamBuilder<List<FamilyRequest>>(
        stream: FamilyService.instance.watchIncomingRequests(),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? const <FamilyRequest>[];
          if (requests.isEmpty) return const SizedBox.shrink();
          final glass = NoorifyGlassTheme(context);
          return _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < requests.length; i++) ...[
                  if (i > 0) Divider(height: 14.h, color: glass.glassBorder),
                  _incomingRequestRow(glass, requests[i]),
                ],
              ],
            ),
          );
        },
      ),
    ];
  }

  Widget _incomingRequestRow(NoorifyGlassTheme glass, FamilyRequest request) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16.r,
          backgroundColor: _teal.withValues(alpha: 0.2),
          backgroundImage: request.fromPhoto != null
              ? NetworkImage(request.fromPhoto!)
              : null,
          child: request.fromPhoto == null
              ? Text(
                  request.fromInitial,
                  style: TextStyle(
                    color: _teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
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
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: glass.textPrimary,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                request.relation == null
                    ? _text(
                        'wants to add you as family',
                        'আপনাকে পরিবারে যোগ করতে চায়',
                      )
                    : _text(
                        'wants to add you as ${request.relation!.label(false)}',
                        '${request.relation!.label(true)} হিসেবে যোগ করতে চায়',
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: glass.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: _text('Decline', 'প্রত্যাখ্যান'),
          onPressed: () => FamilyService.instance.decline(request),
          icon: Icon(Icons.close_rounded, color: glass.textMuted, size: 20.r),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: _text('Accept', 'গ্রহণ'),
          onPressed: () => FamilyService.instance.accept(request),
          icon: Icon(Icons.check_circle_rounded, color: _teal, size: 24.r),
        ),
      ],
    );
  }

  /// Lists the requests the user has sent, each with its current status.
  /// Hidden entirely while there are none so the profile stays uncluttered.
  List<Widget> _buildSentRequests() {
    return [
      StreamBuilder<List<FamilyRequest>>(
        stream: FamilyService.instance.watchOutgoingRequests(),
        builder: (context, snapshot) {
          // Accepted requests graduate to the family-members list above, so the
          // sent list only tracks what's still pending or was declined.
          final requests = (snapshot.data ?? const <FamilyRequest>[])
              .where((r) => r.status != FamilyRequestStatus.accepted)
              .toList();
          if (requests.isEmpty) return const SizedBox.shrink();
          final glass = NoorifyGlassTheme(context);
          return _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < requests.length; i++) ...[
                  if (i > 0) Divider(height: 14.h, color: glass.glassBorder),
                  _sentRequestRow(glass, requests[i]),
                ],
              ],
            ),
          );
        },
      ),
    ];
  }

  Widget _sentRequestRow(NoorifyGlassTheme glass, FamilyRequest request) {
    final name = request.toName.trim().isEmpty
        ? _text('Noorify user', 'নূরিফাই ব্যবহারকারী')
        : request.toName.trim();
    return Row(
      children: [
        CircleAvatar(
          radius: 13.r,
          backgroundColor: _teal.withValues(alpha: 0.2),
          backgroundImage: request.toPhoto != null
              ? NetworkImage(request.toPhoto!)
              : null,
          child: request.toPhoto == null
              ? Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: TextStyle(
                    color: _teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
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
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: glass.textPrimary,
                ),
              ),
              if (request.relation != null || request.toEmail != null)
                Text(
                  [
                    if (request.relation != null)
                      request.relation!.label(_isBangla),
                    if (request.toEmail != null) request.toEmail!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    color: glass.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        _statusPill(request.status),
      ],
    );
  }

  Widget _statusPill(FamilyRequestStatus status) {
    late final Color color;
    late final String label;
    switch (status) {
      case FamilyRequestStatus.accepted:
        color = const Color(0xFF2E9E5B);
        label = _text('Accepted', 'গৃহীত');
        break;
      case FamilyRequestStatus.declined:
        color = const Color(0xFFE5484D);
        label = _text('Declined', 'প্রত্যাখ্যাত');
        break;
      case FamilyRequestStatus.pending:
        color = const Color(0xFFD9821B);
        label = _text('Pending', 'অপেক্ষমাণ');
        break;
      case FamilyRequestStatus.unknown:
        color = const Color(0xFF8A8A8A);
        label = _text('Unknown', 'অজানা');
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

  Widget _familyChip(NoorifyGlassTheme glass, FamilyMember member) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _teal.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11.r,
            backgroundColor: _teal.withValues(alpha: 0.2),
            backgroundImage: member.photoUrl != null
                ? NetworkImage(member.photoUrl!)
                : null,
            child: member.photoUrl == null
                ? Text(
                    member.initial,
                    style: TextStyle(
                      color: _teal,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.sp,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 6.w),
          Text(
            member.resolvedName,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: glass.textPrimary,
            ),
          ),
          if (member.relation != null) ...[
            SizedBox(width: 5.w),
            Text(
              '· ${member.relation!.label(_isBangla)}',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: glass.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: const BoxDecoration(
        color: Color(0xFFE5484D),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
