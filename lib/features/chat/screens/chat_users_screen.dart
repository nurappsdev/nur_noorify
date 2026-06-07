import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/chat/models/chat_user.dart';
import 'package:first_project/features/chat/screens/chat_conversation_screen.dart';
import 'package:first_project/features/chat/services/chat_service.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class ChatUsersScreen extends StatelessWidget {
  const ChatUsersScreen({super.key});

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('Chat', 'চ্যাট'),
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: glass.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      t(
                        'Start a conversation with another member',
                        'অন্য সদস্যের সাথে কথোপকথন শুরু করুন',
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
                child: StreamBuilder<List<ChatUser>>(
                  stream: ChatService.instance.watchUsers(),
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
                          'Could not load users',
                          'ব্যবহারকারী লোড করা যায়নি',
                        ),
                      );
                    }

                    final users = snapshot.data ?? const <ChatUser>[];
                    if (users.isEmpty) {
                      return _CenterMessage(
                        glass: glass,
                        icon: Icons.people_outline_rounded,
                        text: t(
                          'No other users yet',
                          'এখনো অন্য কোনো ব্যবহারকারী নেই',
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 14.h),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        return _UserTile(
                          glass: glass,
                          user: users[index],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ChatConversationScreen(
                                  peer: users[index],
                                ),
                              ),
                            );
                          },
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

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.glass,
    required this.user,
    required this.onTap,
  });

  final NoorifyGlassTheme glass;
  final ChatUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NoorifyGlassCard(
      radius: BorderRadius.circular(16.r),
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 24.r,
          backgroundColor: glass.accent.withValues(alpha: 0.18),
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(
                  user.initial,
                  style: TextStyle(
                    color: glass.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp,
                  ),
                )
              : null,
        ),
        title: Text(
          user.resolvedName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: glass.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15.sp,
          ),
        ),
        subtitle: user.email.trim().isEmpty
            ? null
            : Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: glass.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
        trailing: Icon(
          Icons.chat_bubble_outline_rounded,
          color: glass.accent,
          size: 20.r,
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
