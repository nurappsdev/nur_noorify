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
