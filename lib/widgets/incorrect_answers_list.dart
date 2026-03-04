import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/profile_model.dart';
import '../services/report_service.dart';

class IncorrectAnswersList extends StatefulWidget {
  final String? studentId;
  const IncorrectAnswersList({super.key, this.studentId});

  @override
  State<IncorrectAnswersList> createState() => _IncorrectAnswersListState();
}

class _IncorrectAnswersListState extends State<IncorrectAnswersList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchIncorrectAnswers(
        studentId: widget.studentId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final incorrect = provider.incorrectAnswers;
    final scheme = Theme.of(context).colorScheme;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (incorrect.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_rounded,
              size: 80,
              color: scheme.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No diagnostic gaps detected.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mistakes Diagnostic',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.5,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    '${incorrect.length} entries identified',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () {
                  final studentName =
                      widget.studentId != null && incorrect.isNotEmpty
                      ? (incorrect.first.student?.fullName ??
                            provider.students
                                .firstWhere((s) => s.id == widget.studentId)
                                .fullName)
                      : null;

                  ReportService.printIncorrectAnswersReport(
                    answers: incorrect,
                    title: 'Diagnostic Report',
                    studentName: studentName,
                  );
                },
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Export PDF'),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: incorrect.length,
            itemBuilder: (context, index) {
              final answer = incorrect[index];
              final studentFallback = provider.students.firstWhere(
                (s) => s.id == answer.studentId,
                orElse: () => Profile(
                  id: answer.studentId,
                  fullName: 'Unknown Student',
                  username: '',
                  accessKey: '',
                  updatedAt: DateTime.now(),
                ),
              );
              final fullName =
                  answer.student?.fullName ?? studentFallback.fullName;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: scheme.errorContainer.withValues(alpha: 0.2),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: scheme.error,
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fullName ?? 'Student',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              answer.createdAt.toString().split(' ').first,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_stories_rounded,
                                  size: 14,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  answer.question?.lesson?.title ??
                                      'General Lesson',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              answer.question?.questionText ??
                                  'Question content unavailable',
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.history_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Recorded Answer: ${answer.answerValue ?? "N/A"}',
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
