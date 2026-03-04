import 'package:flutter/material.dart';
import '../../models/student_answer_model.dart';
import '../../services/supabase_service.dart';
import '../../models/question_model.dart';

class StudentAnswersScreen extends StatefulWidget {
  final String studentId;
  final String lessonId;
  final String lessonTitle;
  const StudentAnswersScreen({
    super.key,
    required this.studentId,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<StudentAnswersScreen> createState() => _StudentAnswersScreenState();
}

class _StudentAnswersScreenState extends State<StudentAnswersScreen> {
  final SupabaseService _service = SupabaseService();
  List<StudentAnswer> _answers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnswers();
  }

  Future<void> _loadAnswers() async {
    setState(() => _isLoading = true);
    try {
      _answers = await _service.getStudentAnswers(
        widget.studentId,
        widget.lessonId,
      );
    } catch (e) {
      debugPrint('Error loading answers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getCorrectAnswer(StudentAnswer ans) {
    if (ans.question == null) return "N/A";
    final config = ans.question!.config;

    // Check for "correct_answer" key which seems to be used across types
    if (config.containsKey('correct_answer')) {
      return config['correct_answer'].toString();
    }

    switch (ans.question!.questionType) {
      case QuestionType.mcq:
        final options = config['options'] as List?;
        final correctIndex = config['correct_index'];
        if (options != null &&
            correctIndex != null &&
            correctIndex < options.length) {
          return options[correctIndex];
        }
        return "Unknown";
      case QuestionType.true_false:
        if (config.containsKey('is_correct_true')) {
          return config['is_correct_true'] == true ? "True" : "False";
        }
        return "N/A";
      case QuestionType.code_completion:
        return config['solution'] ?? "N/A";
    }
  }

  void _showEditDialog(StudentAnswer ans) {
    final scoreController = TextEditingController(
      text: ans.scoreAttained.toString(),
    );
    final answerController = TextEditingController(
      text: ans.answerValue?.toString() ?? "",
    );
    bool isCorrect = ans.isCorrect;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Student Answer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: answerController,
                  decoration: const InputDecoration(
                    labelText: 'Student Answer',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: scoreController,
                  decoration: const InputDecoration(
                    labelText: 'Score Attained',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Correct?'),
                  value: isCorrect,
                  onChanged: (val) => setDialogState(() => isCorrect = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final score = int.tryParse(scoreController.text) ?? 0;
                await _service.updateStudentAnswer(
                  ans.id,
                  answerValue: answerController.text,
                  isCorrect: isCorrect,
                  score: score,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadAnswers();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom + 96;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Answers: ${widget.lessonTitle}',
          style: const TextStyle(fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnswers,
              child: _answers.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No answers recorded')),
                      ],
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _answers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ans = _answers[index];
                        final correctAnswer = _getCorrectAnswer(ans);

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      ans.isCorrect
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: ans.isCorrect
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ans.question?.questionText ??
                                                'Question',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Points weight: ${ans.question?.points ?? 0}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _showEditDialog(ans),
                                      tooltip: 'Edit grade',
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  'Correct Answer:',
                                  correctAnswer,
                                  Colors.green.shade700,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  'Student Answer:',
                                  ans.answerValue?.toString() ?? "-",
                                  ans.isCorrect
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.blue.shade100),
                                  ),
                                  child: Text(
                                    'Score: ${ans.scoreAttained} / ${ans.question?.points ?? 0}',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
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

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
