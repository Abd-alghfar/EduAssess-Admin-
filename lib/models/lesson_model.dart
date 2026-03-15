class Lesson {
  final String id;
  final String? assignmentId;
  final String title;
  final int? durationMinutes;
  final bool shuffleQuestions;
  final bool isPublished;
  final DateTime createdAt;

  Lesson({
    required this.id,
    this.assignmentId,
    required this.title,
    this.durationMinutes,
    this.shuffleQuestions = true,
    this.isPublished = false,
    required this.createdAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      assignmentId: json['assignment_id'],
      title: json['title'],
      durationMinutes: json['duration_minutes'],
      shuffleQuestions: json['shuffle_questions'] ?? true,
      isPublished: json['is_published'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      'title': title,
      'duration_minutes': durationMinutes,
      'shuffle_questions': shuffleQuestions,
      'is_published': isPublished,
    };
  }
}
