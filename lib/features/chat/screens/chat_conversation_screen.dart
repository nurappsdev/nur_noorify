import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/chat/models/chat_message.dart';
import 'package:first_project/features/chat/models/chat_user.dart';
import 'package:first_project/features/chat/services/chat_service.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({super.key, required this.peer});

  final ChatUser peer;

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _controller.clear();
    try {
      await ChatService.instance.sendMessage(
        otherUid: widget.peer.uid,
        text: text,
      );
    } catch (_) {
      if (mounted) {
        _controller.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send message')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBangla =
        context.watch<LanguageProvider>().current == AppLanguage.bangla;
    final glass = NoorifyGlassTheme(context);
    String t(String en, String bn) => isBangla ? bn : en;
    final me = ChatService.instance.currentUid;

    return Scaffold(
      backgroundColor: glass.bgBottom,
      appBar: AppBar(
        backgroundColor: glass.glassStart,
        foregroundColor: glass.textPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: glass.accent.withValues(alpha: 0.18),
              backgroundImage: widget.peer.photoUrl != null
                  ? NetworkImage(widget.peer.photoUrl!)
                  : null,
              child: widget.peer.photoUrl == null
                  ? Text(
                      widget.peer.initial,
                      style: TextStyle(
                        color: glass.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                widget.peer.resolvedName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: glass.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
      body: NoorifyGlassBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: ChatService.instance.watchMessages(widget.peer.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: glass.accent),
                      );
                    }

                    final messages = snapshot.data ?? const <ChatMessage>[];
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          t(
                            'Say hello 👋',
                            'সালাম দিন 👋',
                          ),
                          style: TextStyle(
                            color: glass.textSecondary,
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMine = message.senderId == me;
                        return _MessageBubble(
                          glass: glass,
                          text: message.text,
                          isMine: isMine,
                        );
                      },
                    );
                  },
                ),
              ),
              _Composer(
                glass: glass,
                controller: _controller,
                sending: _sending,
                hint: t('Type a message…', 'একটি বার্তা লিখুন…'),
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.glass,
    required this.text,
    required this.isMine,
  });

  final NoorifyGlassTheme glass;
  final String text;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 0.72.sw),
        decoration: BoxDecoration(
          color: isMine ? glass.accent : glass.glassStart,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(isMine ? 16.r : 4.r),
            bottomRight: Radius.circular(isMine ? 4.r : 16.r),
          ),
          border: isMine ? null : Border.all(color: glass.glassBorder),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMine ? Colors.white : glass.textPrimary,
            fontSize: 14.5.sp,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.glass,
    required this.controller,
    required this.sending,
    required this.hint,
    required this.onSend,
  });

  final NoorifyGlassTheme glass;
  final TextEditingController controller;
  final bool sending;
  final String hint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: glass.glassStart,
        border: Border(top: BorderSide(color: glass.glassBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: glass.bgBottom,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(color: glass.glassBorder),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: glass.textPrimary, fontSize: 14.5.sp),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(color: glass.textMuted),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: glass.accent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: sending
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.send_rounded, color: Colors.white, size: 20.r),
            ),
          ),
        ],
      ),
    );
  }
}
