import 'dart:convert';
import 'lesson_model.dart';

enum QuestionType {
  mcq,
  true_false,
  code_completion;

  static QuestionType fromString(String value) {
    return QuestionType.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => QuestionType.mcq,
    );
  }

  String toJson() => toString().split('.').last;
}

class Question {
  final String id;
  final String lessonId;
  final String questionText;
  final QuestionType questionType;
  final Map<String, dynamic> config;
  final int points;
  final DateTime createdAt;
  final Lesson? lesson;

  Question({
    required this.id,
    required this.lessonId,
    required this.questionText,
    required this.questionType,
    required this.config,
    this.points = 1,
    required this.createdAt,
    this.lesson,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      lessonId: json['lesson_id'],
      questionText: json['question_text'],
      questionType: QuestionType.fromString(json['question_type']),
      config: json['config'] is String
          ? jsonDecode(json['config'])
          : Map<String, dynamic>.from(json['config']),
      points: json['points'] ?? 1,
      createdAt: DateTime.parse(json['created_at']),
      lesson: json['lessons'] != null ? Lesson.fromJson(json['lessons']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lesson_id': lessonId,
      'question_text': questionText,
      'question_type': questionType.toJson(),
      'config': config,
      'points': points,
    };
  }
}
