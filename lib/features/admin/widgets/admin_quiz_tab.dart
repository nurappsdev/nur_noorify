import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/features/islamic_quiz/models/quiz_question.dart';
import 'package:first_project/features/islamic_quiz/services/quiz_admin_service.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

/// Admin panel tab: create, edit, enable/disable and delete Firestore quiz
/// questions that get merged into the bundled banks at quiz start.
class AdminQuizTab extends StatefulWidget {
  const AdminQuizTab({super.key});

  @override
  State<AdminQuizTab> createState() => AdminQuizTabState();
}

class AdminQuizTabState extends State<AdminQuizTab> {
  final QuizAdminService _service = QuizAdminService.instance;

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> openEditor({RemoteQuizQuestion? existing}) async {
    final questionEnController = TextEditingController(
      text: existing?.questionEn,
    );
    final questionBnController = TextEditingController(
      text: existing?.questionBn,
    );
    final optionEnControllers = List.generate(
      4,
      (i) => TextEditingController(
        text: (existing?.optionsEn.length ?? 0) > i
            ? existing!.optionsEn[i]
            : '',
      ),
    );
    final optionBnControllers = List.generate(
      4,
      (i) => TextEditingController(
        text: (existing?.optionsBn.length ?? 0) > i
            ? existing!.optionsBn[i]
            : '',
      ),
    );

    var topic = existing?.topic ?? QuizTopic.quran;
    var correctIndex = existing?.correctIndex ?? 0;
    var active = existing?.active ?? true;
    var submitting = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final hasQuestion =
                  questionEnController.text.trim().isNotEmpty ||
                  questionBnController.text.trim().isNotEmpty;
              if (!hasQuestion) {
                _showMessage('Add the question in at least one language.');
                return;
              }

              final optionsEn = optionEnControllers
                  .map((controller) => controller.text.trim())
                  .toList();
              final optionsBn = optionBnControllers
                  .map((controller) => controller.text.trim())
                  .toList();
              final enComplete = optionsEn.every((option) => option.isNotEmpty);
              final bnComplete = optionsBn.every((option) => option.isNotEmpty);
              if (!enComplete && !bnComplete) {
                _showMessage(
                  'Fill all 4 options in at least one language.',
                );
                return;
              }

              setDialogState(() => submitting = true);
              try {
                await _service.upsertQuestion(
                  id: existing?.id,
                  topic: topic,
                  questionEn: questionEnController.text,
                  questionBn: questionBnController.text,
                  optionsEn: enComplete ? optionsEn : optionsBn,
                  optionsBn: bnComplete ? optionsBn : optionsEn,
                  correctIndex: correctIndex,
                  active: active,
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              } catch (e) {
                _showMessage('Failed to save question: $e');
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => submitting = false);
                }
              }
            }

            return AlertDialog(
              title: Text(
                existing == null ? 'Add Quiz Question' : 'Edit Quiz Question',
              ),
              content: SizedBox(
                width: 420.w,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<QuizTopic>(
                        initialValue: topic,
                        decoration: const InputDecoration(labelText: 'Topic'),
                        items: QuizTopic.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.label(false)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => topic = value);
                        },
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: questionEnController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Question (English)',
                        ),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: questionBnController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Question (Bangla)',
                        ),
                      ),
                      SizedBox(height: 14.h),
                      RadioGroup<int>(
                        groupValue: correctIndex,
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => correctIndex = value);
                        },
                        child: Column(
                          children: [
                            for (var i = 0; i < 4; i++) ...[
                              Row(
                                children: [
                                  Radio<int>(value: i),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        TextField(
                                          controller: optionEnControllers[i],
                                          decoration: InputDecoration(
                                            labelText:
                                                'Option ${i + 1} (English)',
                                            isDense: true,
                                          ),
                                        ),
                                        SizedBox(height: 6.h),
                                        TextField(
                                          controller: optionBnControllers[i],
                                          decoration: InputDecoration(
                                            labelText:
                                                'Option ${i + 1} (Bangla)',
                                            isDense: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        'Select the radio button next to the correct answer.',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        subtitle: const Text('Visible to users in the quiz'),
                        value: active,
                        onChanged: (value) {
                          setDialogState(() => active = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? SizedBox(
                          width: 16.r,
                          height: 16.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    questionEnController.dispose();
    questionBnController.dispose();
    for (final controller in optionEnControllers) {
      controller.dispose();
    }
    for (final controller in optionBnControllers) {
      controller.dispose();
    }

    if (saved == true) {
      _showMessage('Quiz question saved.');
    }
  }

  Future<void> _confirmDelete(RemoteQuizQuestion question) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete question?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (sure != true) return;

    try {
      await _service.deleteQuestion(question.id);
      _showMessage('Question deleted.');
    } catch (e) {
      _showMessage('Delete failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return StreamBuilder<List<RemoteQuizQuestion>>(
      stream: _service.watchAllQuestions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Text(
                'Failed to load quiz questions.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final questions = snapshot.data ?? const <RemoteQuizQuestion>[];
        if (questions.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: const Text(
                'No custom quiz questions yet.\nTap "Add Question" to create one.\nUsers will see them alongside the built-in questions.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 90.h),
          itemCount: questions.length,
          separatorBuilder: (_, _) => SizedBox(height: 10.h),
          itemBuilder: (context, index) =>
              _questionCard(glass, questions[index]),
        );
      },
    );
  }

  Widget _questionCard(NoorifyGlassTheme glass, RemoteQuizQuestion question) {
    final title = question.questionBn.isNotEmpty
        ? question.questionBn
        : question.questionEn;
    final options = question.optionsBn.isNotEmpty
        ? question.optionsBn
        : question.optionsEn;
    final correct =
        (question.correctIndex >= 0 && question.correctIndex < options.length)
        ? options[question.correctIndex]
        : '?';

    return NoorifyGlassCard(
      radius: BorderRadius.circular(16.r),
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: glass.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999.r),
                  color: question.active
                      ? const Color(0x2436D57A)
                      : const Color(0x24A0A8B1),
                ),
                child: Text(
                  question.active ? 'Active' : 'Hidden',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: question.active
                        ? const Color(0xFF3AD37E)
                        : glass.textMuted,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            '${question.topic.label(false)} • Answer: $correct',
            style: TextStyle(color: glass.textSecondary, fontSize: 11.5.sp),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => openEditor(existing: question),
                icon: Icon(Icons.edit_outlined, size: 16.sp),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await _service.setActive(question.id, !question.active);
                    _showMessage(
                      question.active ? 'Question hidden.' : 'Question live.',
                    );
                  } catch (e) {
                    _showMessage('Status update failed: $e');
                  }
                },
                icon: Icon(Icons.toggle_on_rounded, size: 16.sp),
                label: Text(question.active ? 'Hide' : 'Activate'),
              ),
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(question),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE75F6D),
                ),
                icon: Icon(Icons.delete_outline_rounded, size: 16.sp),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
