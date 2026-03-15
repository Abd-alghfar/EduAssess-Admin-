import 'question_model.dart';
import 'profile_model.dart';

class StudentAnswer {
  final String id;
  final String? attemptId;
  final String questionId;
  final dynamic answerValue;
  final bool isCorrect;
  final int pointsEarned;
  final Question? question;
  final Profile? student;
  final DateTime? createdAt; // Taken from attempt

  StudentAnswer({
    required this.id,
    this.attemptId,
    required this.questionId,
    required this.answerValue,
    required this.isCorrect,
    required this.pointsEarned,
    this.question,
    this.student,
    this.createdAt,
  });

  String? get studentId => student?.id;

  factory StudentAnswer.fromJson(Map<String, dynamic> json) {
    final attemptJson = json['exam_attempts'];
    final profileJson = attemptJson?['profiles'];

    return StudentAnswer(
      id: json['id'],
      attemptId: json['attempt_id'],
      questionId: json['question_id'],
      answerValue: json['student_answer'],
      isCorrect: json['is_correct'] ?? false,
      pointsEarned: json['points_earned'] ?? 0,
      question: json['questions'] != null
          ? Question.fromJson(json['questions'])
          : null,
      student: profileJson != null ? Profile.fromJson(profileJson) : null,
      createdAt: attemptJson?['completed_at'] != null
          ? DateTime.parse(attemptJson['completed_at'])
          : (attemptJson?['started_at'] != null
                ? DateTime.parse(attemptJson['started_at'])
                : null),
    );
  }
}
