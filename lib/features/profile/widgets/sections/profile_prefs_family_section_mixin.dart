part of '../../screens/profile_preferences_screen.dart';

/// Profile section that lists the user's accepted family members with their
/// relationship. Sending and responding to requests now lives on the
/// Notifications screen, so this section is read-only.
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
                  style: TextStyle(fontSize: 12.sp, color: glass.textSecondary),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < members.length; i++) ...[
                  if (i > 0) Divider(height: 16.h, color: glass.glassBorder),
                  _familyMemberRow(glass, members[i]),
                ],
              ],
            );
          },
        ),
      ),
    ];
  }

  Widget _familyMemberRow(NoorifyGlassTheme glass, FamilyMember member) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18.r,
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
                    fontSize: 14.sp,
                  ),
                )
              : null,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.resolvedName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: glass.textPrimary,
                ),
              ),
              if (member.relation != null) ...[
                SizedBox(height: 2.h),
                Text(
                  member.relation!.label(_isBangla),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: glass.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
