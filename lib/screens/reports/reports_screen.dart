import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../students/student_detail_screen.dart';
import '../../widgets/incorrect_answers_list.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchStudents();
      context.read<AdminProvider>().fetchIncorrectAnswers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: const Text(
            'Academic Analytics',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 4,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            tabs: const [
              Tab(icon: Icon(Icons.analytics_rounded), text: 'Diagnostics'),
              Tab(icon: Icon(Icons.insights_rounded), text: 'Student Profiles'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [IncorrectAnswersList(), StudentPerformanceTab()],
        ),
      ),
    );
  }
}

class StudentPerformanceTab extends StatelessWidget {
  const StudentPerformanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final students = provider.students;
    final incorrect = provider.incorrectAnswers;
    final scheme = Theme.of(context).colorScheme;

    final Map<String, int> mistakeCounts = {};
    for (final ans in incorrect) {
      mistakeCounts[ans.studentId] = (mistakeCounts[ans.studentId] ?? 0) + 1;
    }

    if (provider.isLoading && students.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final count = mistakeCounts[student.id] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primary.withValues(alpha: 0.08),
              child: Text(
                student.fullName?.substring(0, 1).toUpperCase() ?? 'S',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
            title: Text(
              student.fullName ?? 'No Name',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '@${student.username}',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count Insights',
                      style: TextStyle(
                        color: scheme.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.verified_rounded,
                    color: Colors.green,
                    size: 24,
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentDetailScreen(student: student),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
