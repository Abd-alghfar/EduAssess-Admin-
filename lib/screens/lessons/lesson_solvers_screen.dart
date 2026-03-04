import 'package:flutter/material.dart';
import '../../models/profile_model.dart';
import '../../services/supabase_service.dart';
import '../students/student_answers_screen.dart';
import '../../widgets/shimmer_loader.dart';

class LessonSolversScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;

  const LessonSolversScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<LessonSolversScreen> createState() => _LessonSolversScreenState();
}

class _LessonSolversScreenState extends State<LessonSolversScreen> {
  final SupabaseService _service = SupabaseService();
  List<Profile> _solvers = [];
  List<Profile> _attempted = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSolvers();
  }

  Future<void> _loadSolvers() async {
    setState(() => _isLoading = true);
    try {
      _solvers = await _service.getStudentsWhoSolvedLesson(widget.lessonId);
      _attempted = await _service.getStudentsWhoAttemptedLesson(
        widget.lessonId,
      );
      if (_solvers.isNotEmpty) {
        final solvedIds = _solvers.map((s) => s.id).toSet();
        _attempted = _attempted
            .where((s) => !solvedIds.contains(s.id))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading solvers: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom + 96;
    return Scaffold(
      appBar: AppBar(title: Text('Students who solved: ${widget.lessonTitle}')),
      body: _isLoading
          ? const ListShimmer()
          : RefreshIndicator(
              onRefresh: _loadSolvers,
              child: _solvers.isEmpty && _attempted.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: _buildEmptyState(),
                        ),
                      ],
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
                      children: [
                        if (_solvers.isNotEmpty) ...[
                          _buildSectionHeader('Solved', Colors.green.shade700),
                          const SizedBox(height: 12),
                          ..._solvers.map(
                            (student) => _buildStudentCard(student),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (_attempted.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Attempted',
                            Colors.orange.shade700,
                          ),
                          const SizedBox(height: 12),
                          ..._attempted.map(
                            (student) => _buildStudentCard(
                              student,
                              badge: 'Attempted',
                              badgeColor: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
    );
  }

  Widget _buildStudentCard(
    Profile student, {
    String? badge,
    Color? badgeColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            (student.fullName ?? '?')[0].toUpperCase(),
            style: TextStyle(color: Colors.blue.shade700),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                student.fullName ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (badgeColor ?? Colors.grey).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor ?? Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text('@${student.username ?? "N/A"}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentAnswersScreen(
                studentId: student.id,
                lessonId: widget.lessonId,
                lessonTitle: widget.lessonTitle,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No students have solved this quiz yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
