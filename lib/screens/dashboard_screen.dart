import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'students/add_student_dialog.dart';
import 'lessons/add_lesson_dialog.dart';
import 'questions/questions_list_screen.dart';
import '../models/lesson_model.dart';
import 'lessons/lessons_screen.dart';
import 'reports/reports_screen.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/performance_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchStudents();
      context.read<AdminProvider>().fetchLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom + 96;

    if (provider.isLoading && provider.students.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: DashboardShimmer(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AdminProvider>().fetchStudents();
          await context.read<AdminProvider>().fetchLessons();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeader(scheme),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildStatCard(
                    context,
                    'Total Students',
                    provider.students.length.toString(),
                    FontAwesomeIcons.users,
                    scheme.primary,
                    scheme.tertiary,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    context,
                    'Active Quizzes',
                    provider.lessons.length.toString(),
                    FontAwesomeIcons.bookOpen,
                    const Color(0xFFF59E0B),
                    scheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // NEW Feature: Performance Chart
              PerformanceChart(data: provider.completionTrend),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick Discovery',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Build fast. Teach smarter.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionCard(
                      context,
                      'Add Student',
                      FontAwesomeIcons.userPlus,
                      scheme.primary,
                      () {
                        showDialog(
                          context: context,
                          builder: (context) => const AddStudentDialog(),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildActionCard(
                      context,
                      'New Quiz',
                      FontAwesomeIcons.plus,
                      scheme.secondary,
                      () async {
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
                            builder: (context) =>
                                QuestionsListScreen(lesson: created),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildActionCard(
                      context,
                      'Analytics',
                      FontAwesomeIcons.chartBar,
                      scheme.tertiary,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Lesson Success Rates Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quiz Performance',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LessonsScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Consumer<AdminProvider>(
                builder: (context, adminProvider, child) {
                  final lessons = adminProvider.lessons;
                  final rates = adminProvider.lessonSuccessRates;
                  if (lessons.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'No quizzes deployed yet.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    );
                  }
                  final visible = lessons.take(3).toList();
                  return Column(
                    children: visible.map((lesson) {
                      final rate = rates[lesson.id] ?? 0.0;
                      return _buildLessonProgressCard(
                        context,
                        lesson,
                        rate,
                        adminProvider.lessonCompletionCounts[lesson.id] ?? 0,
                        scheme,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F172A),
            const Color(0xFF1E293B),
            scheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(
              FontAwesomeIcons.rocket,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '2026 Academic Intel v2.0',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color colorStart,
    Color colorEnd,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: colorStart.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorStart.withValues(alpha: 0.2),
                    colorEnd.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colorStart, size: 20),
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonProgressCard(
    BuildContext context,
    Lesson lesson,
    double rate,
    int count,
    ColorScheme scheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                FontAwesomeIcons.graduationCap,
                size: 20,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completed by $count students',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: rate / 100,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: scheme.primary,
                      minHeight: 6,
                    ),
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
