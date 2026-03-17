import 'question_model.dart';

class QuestionBankItem {
  final String id;
  final String teacherId;
  final String questionText;
  final QuestionType questionType;
  final Map<String, dynamic> config;
  final int points;
  final String? difficulty;
  final String? unit;
  final String? topic;
  final DateTime createdAt;

  QuestionBankItem({
    required this.id,
    required this.teacherId,
    required this.questionText,
    required this.questionType,
    required this.config,
    required this.points,
    this.difficulty,
    this.unit,
    this.topic,
    required this.createdAt,
  });

  factory QuestionBankItem.fromJson(Map<String, dynamic> json) {
    return QuestionBankItem(
      id: json['id'],
      teacherId: json['teacher_id'],
      questionText: json['question_text'],
      questionType: QuestionType.fromString(json['question_type']),
      config: Map<String, dynamic>.from(json['config'] ?? {}),
      points: json['points'] ?? 1,
      difficulty: json['difficulty'],
      unit: json['unit'],
      topic: json['topic'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teacher_id': teacherId,
      'question_text': questionText,
      'question_type': questionType.toJson(),
      'config': config,
      'points': points,
      'difficulty': difficulty,
      'unit': unit,
      'topic': topic,
    };
  }
}
