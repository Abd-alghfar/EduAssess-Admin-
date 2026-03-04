class StudentProgress {
  final String id;
  final String studentId;
  final String lessonId;
  final String? lessonTitle;
  final DateTime completedAt;
  final int totalScore;

  StudentProgress({
    required this.id,
    required this.studentId,
    required this.lessonId,
    this.lessonTitle,
    required this.completedAt,
    required this.totalScore,
  });

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      id: json['id'],
      studentId: json['student_id'],
      lessonId: json['lesson_id'],
      lessonTitle: json['lessons']?['title'],
      completedAt: DateTime.parse(json['completed_at']),
      totalScore: json['total_score'] ?? 0,
    );
  }
}
