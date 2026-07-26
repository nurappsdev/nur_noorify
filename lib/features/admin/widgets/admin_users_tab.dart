import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/features/admin/services/admin_role_service.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

/// Admin panel tab: total registered users, searchable list, and
/// promote/demote admin actions.
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggleAdmin({
    required String uid,
    required String name,
    required bool makeAdmin,
  }) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(makeAdmin ? 'Make admin?' : 'Remove admin?'),
          content: Text(
            makeAdmin
                ? '"$name" will get full access to this admin panel.'
                : '"$name" will lose admin panel access.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    if (sure != true) return;

    try {
      await AdminRoleService.instance.setUserRole(
        uid,
        makeAdmin ? 'admin' : 'user',
      );
      _showMessage(makeAdmin ? '$name is now an admin.' : 'Admin removed.');
    } catch (e) {
      _showMessage('Role update failed: $e');
    }
  }

  DateTime? _dateOf(Map<String, dynamic> data, String key) {
    final raw = data[key];
    if (raw is Timestamp) return raw.toDate();
    return null;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'unknown';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AdminRoleService.instance.watchAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Text(
                'Failed to load users.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? const [];
        final admins = docs
            .where((doc) => AdminRoleService.instance.isAdminData(doc.data()))
            .length;

        final query = _query.trim().toLowerCase();
        final visible = query.isEmpty
            ? docs
            : docs.where((doc) {
                final data = doc.data();
                final name = (data['display_name'] ?? '')
                    .toString()
                    .toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                return name.contains(query) || email.contains(query);
              }).toList();

        final sorted = [...visible]..sort((a, b) {
          final aDate = _dateOf(a.data(), 'created_at');
          final bDate = _dateOf(b.data(), 'created_at');
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

        return ListView(
          padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 90.h),
          children: [
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    glass,
                    icon: Icons.people_alt_outlined,
                    label: 'Registered users',
                    value: '${docs.length}',
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _statCard(
                    glass,
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admins',
                    value: '$admins',
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            NoorifyGlassCard(
              radius: BorderRadius.circular(14.r),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, size: 18.sp),
                  hintText: 'Search by name or email',
                ),
              ),
            ),
            SizedBox(height: 10.h),
            if (sorted.isEmpty)
              Padding(
                padding: EdgeInsets.all(24.r),
                child: const Center(child: Text('No users found.')),
              )
            else
              ...sorted.map((doc) => _userCard(glass, doc)),
          ],
        );
      },
    );
  }

  Widget _statCard(
    NoorifyGlassTheme glass, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return NoorifyGlassCard(
      radius: BorderRadius.circular(14.r),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 22.sp, color: glass.accent),
          SizedBox(width: 10.w),
          Column(
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
        ],
      ),
    );
  }

  Widget _userCard(
    NoorifyGlassTheme glass,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final name = (data['display_name'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final photoUrl = (data['photo_url'] ?? '').toString();
    final isAdmin = AdminRoleService.instance.isAdminData(data);
    final rawPoints = data['points'];
    final points = rawPoints is num ? rawPoints.toInt() : 0;
    final joined = _formatDate(_dateOf(data, 'created_at'));
    final isSelf = doc.id == FirebaseAuth.instance.currentUser?.uid;
    final displayName = name.isNotEmpty
        ? name
        : (email.isNotEmpty ? email : doc.id);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: NoorifyGlassCard(
        radius: BorderRadius.circular(16.r),
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? Icon(Icons.person_outline_rounded, size: 20.sp)
                  : null,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: glass.textPrimary,
                          ),
                        ),
                      ),
                      if (isAdmin) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999.r),
                            color: const Color(0x2438BDF8),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5BC8FF),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (email.isNotEmpty && name.isNotEmpty)
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: glass.textSecondary,
                      ),
                    ),
                  Text(
                    '$points points • joined $joined',
                    style: TextStyle(fontSize: 10.5.sp, color: glass.textMuted),
                  ),
                ],
              ),
            ),
            if (!isSelf)
              IconButton(
                tooltip: isAdmin ? 'Remove admin' : 'Make admin',
                onPressed: () => _toggleAdmin(
                  uid: doc.id,
                  name: displayName,
                  makeAdmin: !isAdmin,
                ),
                icon: Icon(
                  isAdmin
                      ? Icons.remove_moderator_outlined
                      : Icons.add_moderator_outlined,
                  size: 20.sp,
                  color: isAdmin ? const Color(0xFFE75F6D) : glass.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
