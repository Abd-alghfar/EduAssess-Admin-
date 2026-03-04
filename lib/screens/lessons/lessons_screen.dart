import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
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
      context.read<AdminProvider>().fetchLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom + 96;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Exam Control Center'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
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
                    builder: (context) => QuestionsListScreen(lesson: created),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Exam'),
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const GridShimmer()
          : provider.lessons.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () => context.read<AdminProvider>().fetchLessons(),
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset),
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisExtent: 220,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: provider.lessons.length,
                itemBuilder: (context, index) {
                  final lesson = provider.lessons[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  lesson.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            AddLessonDialog(lesson: lesson),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _confirmDelete(lesson.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              lesson.description ?? 'No description',
                              style: TextStyle(color: Colors.grey.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LessonSolversScreen(
                                        lessonId: lesson.id,
                                        lessonTitle: lesson.title,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.userCheck,
                                        size: 14,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${provider.lessonCompletionCounts[lesson.id] ?? 0} Completed',
                                        style: TextStyle(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.secondary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.chartLine,
                                      size: 14,
                                      color: scheme.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${provider.lessonSuccessRates[lesson.id]?.toStringAsFixed(1) ?? "0.0"}%',
                                      style: TextStyle(
                                        color: scheme.secondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        QuestionsListScreen(lesson: lesson),
                                  ),
                                );
                              },
                              icon: const Icon(
                                FontAwesomeIcons.listCheck,
                                size: 16,
                              ),
                              label: const Text('Exam Builder'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam?'),
        content: const Text(
          'This will delete all questions associated with this examination.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AdminProvider>().deleteLesson(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
          Icon(
            FontAwesomeIcons.bookOpenReader,
            size: 64,
            color: scheme.primary.withOpacity(0.35),
          ),
          const SizedBox(height: 16),
          Text(
            'No exams found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first exam to start adding questions',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
