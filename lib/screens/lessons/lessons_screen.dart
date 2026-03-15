import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/teacher_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'add_lesson_dialog.dart';
import '../questions/questions_list_screen.dart';
import 'lesson_solvers_screen.dart';
import '../../models/lesson_model.dart';
import '../../widgets/shimmer_loader.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherProvider>().fetchLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherProvider>();
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom + 100;

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Assessment Hub',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton.filledTonal(
                  onPressed: () async {
                    final isPhone = MediaQuery.of(context).size.width < 600;
                    final created = await (isPhone
                        ? Navigator.push<Lesson>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AddLessonDialog(fullScreen: true),
                            ),
                          )
                        : showDialog<Lesson>(
                            context: context,
                            builder: (context) => const AddLessonDialog(),
                          ));
                    if (!context.mounted || created == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            QuestionsListScreen(lesson: created),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_task_rounded),
                ),
              ),
            ],
          ),
          if (provider.isLoading && provider.lessons.isEmpty)
            const SliverFillRemaining(child: GridShimmer())
          else if (provider.lessons.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 500,
                  mainAxisExtent: 240,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final lesson = provider.lessons[index];
                  return _buildLessonCard(lesson, scheme, provider);
                }, childCount: provider.lessons.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(
    Lesson lesson,
    ColorScheme scheme,
    TeacherProvider provider,
  ) {
    final completionCount = provider.lessonCompletionCounts[lesson.id] ?? 0;
    final successRate = provider.lessonSuccessRates[lesson.id] ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionsListScreen(lesson: lesson),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${lesson.createdAt.toString().split(' ').first}',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        if (lesson.scheduledAt != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Scheduled: ${lesson.scheduledAt!.day}/${lesson.scheduledAt!.month} ${lesson.scheduledAt!.hour}:${lesson.scheduledAt!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (lesson.expiresAt != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_off_outlined,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ends: ${lesson.expiresAt!.day}/${lesson.expiresAt!.month} ${lesson.expiresAt!.hour}:${lesson.expiresAt!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    Icons.edit_rounded,
                    scheme.onSurfaceVariant,
                    () {
                      showDialog(
                        context: context,
                        builder: (context) => AddLessonDialog(lesson: lesson),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    Icons.delete_outline_rounded,
                    Colors.redAccent,
                    () => _confirmDelete(lesson.id),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _buildStat(
                    FontAwesomeIcons.circleCheck,
                    '$completionCount Done',
                    scheme.primary,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonSolversScreen(
                          lessonId: lesson.id,
                          lessonTitle: lesson.title,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStat(
                    FontAwesomeIcons.bolt,
                    '${successRate.toStringAsFixed(1)}%',
                    Colors.orange,
                    null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuestionsListScreen(lesson: lesson),
                    ),
                  ),
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                  label: const Text('Manage Questions'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildStat(
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Assessment?'),
        content: const Text(
          'This action is irreversible and will delete all associated question data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<TeacherProvider>().deleteLesson(id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.fileSignature,
              size: 48,
              color: scheme.primary.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Create Your First Exam',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Build your first assessment to start tracking student progress.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () async {
              final isPhone = MediaQuery.of(context).size.width < 600;
              final created = await (isPhone
                  ? Navigator.push<Lesson>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AddLessonDialog(fullScreen: true),
                      ),
                    )
                  : showDialog<Lesson>(
                      context: context,
                      builder: (context) => const AddLessonDialog(),
                    ));
              if (!mounted || created == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionsListScreen(lesson: created),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Design New Exam'),
          ),
        ],
      ),
    );
  }
}
