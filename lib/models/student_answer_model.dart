import 'question_model.dart';
import 'profile_model.dart';

class StudentAnswer {
  final String id;
  final String studentId;
  final String questionId;
  final dynamic answerValue;
  final bool isCorrect;
  final int scoreAttained;
  final DateTime createdAt;
  final Question? question;
  final Profile? student;

  StudentAnswer({
    required this.id,
    required this.studentId,
    required this.questionId,
    required this.answerValue,
    required this.isCorrect,
    required this.scoreAttained,
    required this.createdAt,
    this.question,
    this.student,
  });

  factory StudentAnswer.fromJson(Map<String, dynamic> json) {
    return StudentAnswer(
      id: json['id'],
      studentId: json['student_id'],
      questionId: json['question_id'],
      answerValue: json['answer_value'],
      isCorrect: json['is_correct'] ?? false,
      scoreAttained: json['score_attained'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      question: json['questions'] != null
          ? Question.fromJson(json['questions'])
          : null,
      student: json['profiles'] != null
          ? Profile.fromJson(json['profiles'])
          : null,
    );
  }
}
