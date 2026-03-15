class ExamAttempt {
  final String id;
  final String studentId;
  final String lessonId;
  final double score;
  final bool isCompleted;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? lessonTitle;

  ExamAttempt({
    required this.id,
    required this.studentId,
    required this.lessonId,
    required this.score,
    required this.isCompleted,
    required this.startedAt,
    this.completedAt,
    this.lessonTitle,
  });

  factory ExamAttempt.fromJson(Map<String, dynamic> json) {
    return ExamAttempt(
      id: json['id'],
      studentId: json['student_id'],
      lessonId: json['lesson_id'],
      score: (json['score'] ?? 0).toDouble(),
      isCompleted: json['is_completed'] ?? false,
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      lessonTitle: json['lessons']?['title'],
    );
  }
}
