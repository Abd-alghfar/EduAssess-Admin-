import 'package:flutter/material.dart';
import '../../models/profile_model.dart';
import '../../models/student_progress_model.dart';
import '../../services/supabase_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'student_answers_screen.dart';
import '../../models/lesson_model.dart';
import '../../widgets/incorrect_answers_list.dart';

class StudentDetailScreen extends StatefulWidget {
  final Profile student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final SupabaseService _service = SupabaseService();
  List<StudentProgress> _progress = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _progress = await _service.getStudentProgress(widget.student.id);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom + 96;
    return Scaffold(
      appBar: AppBar(title: Text(widget.student.fullName ?? 'Student Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    const Text(
                      'Mistakes Report',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 400,
                      child: IncorrectAnswersList(studentId: widget.student.id),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Student Quizzes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<AdminProvider>(
                      builder: (context, adminProvider, child) {
                        final lessons = adminProvider.lessons;
                        if (lessons.isEmpty) {
                          return const Text('No quizzes available');
                        }
                        return Column(
                          children: lessons.map((Lesson lesson) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(lesson.title),
                                trailing: IconButton(
                                  icon: const Icon(Icons.visibility),
                                  tooltip: 'View Answers',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentAnswersScreen(
                                          studentId: widget.student.id,
                                          lessonId: lesson.id,
                                          lessonTitle: lesson.title,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Learning Progress',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _progress.isEmpty
                        ? const Center(child: Text('No progress recorded yet'))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _progress.length,
                            itemBuilder: (context, index) {
                              final p = _progress[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: const Icon(
                                    FontAwesomeIcons.circleCheck,
                                    color: Colors.green,
                                  ),
                                  title: Text(
                                    p.lessonTitle ?? 'Unknown Quiz',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Completed on: ${p.completedAt.toString().split(' ').first}',
                                  ),
                                  trailing: Text(
                                    'Score: ${p.totalScore}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              widget.student.fullName?.substring(0, 1).toUpperCase() ?? 'S',
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.fullName ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${widget.student.username}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.key, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'Access Key: ${widget.student.accessKey}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
