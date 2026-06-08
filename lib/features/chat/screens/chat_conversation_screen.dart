import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/chat/models/chat_message.dart';
import 'package:first_project/features/chat/models/chat_question.dart';
import 'package:first_project/features/chat/models/chat_user.dart';
import 'package:first_project/features/chat/services/chat_service.dart'
    show ChatService, QuestionAlreadySentTodayException;
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
  /// Questions sent this session, newest first — instant feedback / fallback.
  final List<ChatMessage> _localSent = [];

  /// Optimistic answers I've given, keyed by message id.
  final Map<String, String> _localAnswers = {};

  /// Questions already sent in this conversation today, by anyone. These are
  /// locked in the picker so the same check-in can't be sent twice on the same
  /// calendar day. Messages whose server timestamp hasn't resolved yet
  /// (createdAt == null) are treated as sent just now, i.e. today.
  Set<String> _questionsLockedToday(List<ChatMessage> remote) {
    final now = DateTime.now();
    bool isToday(DateTime? when) =>
        when == null ||
        (when.year == now.year &&
            when.month == now.month &&
            when.day == now.day);

    final locked = <String>{};
    for (final message in [...remote, ..._localSent]) {
      if (isToday(message.createdAt)) locked.add(message.text);
    }
    return locked;
  }

  Future<void> _sendQuestion(String question) async {
    final me = ChatService.instance.currentUid ?? 'me';
    final optimistic = ChatMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      senderId: me,
      text: question,
      answer: null,
      createdAt: DateTime.now(),
    );

    setState(() => _localSent.insert(0, optimistic));

    try {
      await ChatService.instance.sendMessage(
        otherUid: widget.peer.uid,
        text: question,
      );
    } on QuestionAlreadySentTodayException {
      if (!mounted) return;
      setState(() => _localSent.removeWhere((m) => m.id == optimistic.id));
      final isBangla =
          context.read<LanguageProvider>().current == AppLanguage.bangla;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBangla
                ? 'এই প্রশ্নটি আজ ইতিমধ্যে পাঠানো হয়েছে'
                : 'You already sent this question today',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sent (not synced yet)')),
        );
      }
    }
  }

  Future<void> _answer(ChatMessage message, String answer) async {
    // Once answered, it's final — ignore further taps on the same question.
    if (message.isAnswered || _localAnswers.containsKey(message.id)) return;
    setState(() => _localAnswers[message.id] = answer);

    try {
      await ChatService.instance.answerMessage(
        otherUid: widget.peer.uid,
        messageId: message.id,
        answer: answer,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer saved (not synced yet)')),
        );
      }
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
          child: StreamBuilder<List<ChatMessage>>(
            stream: ChatService.instance.watchMessages(widget.peer.uid),
            builder: (context, snapshot) {
              final loading =
                  snapshot.connectionState == ConnectionState.waiting &&
                  _localSent.isEmpty;
              final remote = snapshot.data ?? const <ChatMessage>[];
              final messages = remote.isNotEmpty ? remote : _localSent;
              final lockedQuestions = _questionsLockedToday(remote);

              return Column(
                children: [
                  Expanded(
                    child: loading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: glass.accent,
                            ),
                          )
                        : messages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32.w),
                              child: Text(
                                t(
                                  'Tap a question below to send it.',
                                  'পাঠাতে নিচের একটি প্রশ্নে ট্যাপ করুন।',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: glass.textSecondary,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            reverse: true,
                            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMine = message.senderId == me;
                              // Apply any optimistic answer I just gave.
                              final localAnswer = _localAnswers[message.id];
                              final answer = message.isAnswered
                                  ? message.answer
                                  : localAnswer;

                              return _QuestionBubble(
                                glass: glass,
                                question: message.text,
                                isMine: isMine,
                                answer: answer,
                                // The recipient (not the sender) gets Yes/No.
                                showAnswerButtons: !isMine && answer == null,
                                pendingLabel: t(
                                  'Awaiting answer',
                                  'উত্তরের অপেক্ষায়',
                                ),
                                answerLabel: t('Answer', 'উত্তর'),
                                yesLabel: t('Yes', 'হ্যাঁ'),
                                noLabel: t('No', 'না'),
                                onYes: () => _answer(message, 'Yes'),
                                onNo: () => _answer(message, 'No'),
                              );
                            },
                          ),
                  ),
                  _QuestionPicker(
                    glass: glass,
                    questions: kCheckInQuestions,
                    lockedQuestions: lockedQuestions,
                    title: t('Send a check-in question', 'একটি প্রশ্ন পাঠান'),
                    sentTodayLabel: t('Sent today', 'আজ পাঠানো হয়েছে'),
                    onSelect: _sendQuestion,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuestionBubble extends StatelessWidget {
  const _QuestionBubble({
    required this.glass,
    required this.question,
    required this.isMine,
    required this.answer,
    required this.showAnswerButtons,
    required this.pendingLabel,
    required this.answerLabel,
    required this.yesLabel,
    required this.noLabel,
    required this.onYes,
    required this.onNo,
  });

  final NoorifyGlassTheme glass;
  final String question;
  final bool isMine;
  final String? answer;
  final bool showAnswerButtons;
  final String pendingLabel;
  final String answerLabel;
  final String yesLabel;
  final String noLabel;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    final onBubble = isMine ? Colors.white : glass.textPrimary;
    final subtle = isMine
        ? Colors.white.withValues(alpha: 0.85)
        : glass.textSecondary;
    final answered = (answer ?? '').isNotEmpty;
    final answerColor = answer == 'Yes'
        ? const Color(0xFF2E9E5B)
        : const Color(0xFFD7674F);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 0.76.sw),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              question,
              style: TextStyle(color: onBubble, fontSize: 14.5.sp, height: 1.3),
            ),
            SizedBox(height: 8.h),
            if (answered)
              _AnswerChip(label: '$answerLabel: $answer', color: answerColor)
            else if (showAnswerButtons)
              Row(
                children: [
                  _ChoiceButton(
                    label: yesLabel,
                    color: const Color(0xFF2E9E5B),
                    onTap: onYes,
                  ),
                  SizedBox(width: 8.w),
                  _ChoiceButton(
                    label: noLabel,
                    color: const Color(0xFFD7674F),
                    onTap: onNo,
                  ),
                ],
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, size: 13.r, color: subtle),
                  SizedBox(width: 4.w),
                  Text(
                    pendingLabel,
                    style: TextStyle(
                      color: subtle,
                      fontSize: 11.5.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuestionPicker extends StatelessWidget {
  const _QuestionPicker({
    required this.glass,
    required this.questions,
    required this.lockedQuestions,
    required this.title,
    required this.sentTodayLabel,
    required this.onSelect,
  });

  final NoorifyGlassTheme glass;
  final List<String> questions;

  /// Questions already sent today — shown disabled and not tappable.
  final Set<String> lockedQuestions;
  final String title;
  final String sentTodayLabel;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: glass.glassStart,
        border: Border(top: BorderSide(color: glass.glassBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
            child: Text(
              title,
              style: TextStyle(
                color: glass.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 0.34.sh),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: questions.length,
              separatorBuilder: (_, _) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final question = questions[index];
                final locked = lockedQuestions.contains(question);
                return Opacity(
                  opacity: locked ? 0.55 : 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: locked ? null : () => onSelect(question),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: glass.accent.withValues(
                          alpha: locked ? 0.05 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: glass.accent.withValues(
                            alpha: locked ? 0.18 : 0.35,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              question,
                              style: TextStyle(
                                color: glass.textPrimary,
                                fontSize: 13.5.sp,
                                height: 1.25,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          if (locked) ...[
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16.r,
                              color: glass.textMuted,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              sentTodayLabel,
                              style: TextStyle(
                                color: glass.textMuted,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else
                            Icon(
                              Icons.send_rounded,
                              size: 18.r,
                              color: glass.accent,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
