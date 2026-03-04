class Lesson {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final bool showCorrection;
  final int? durationMinutes;

  Lesson({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.showCorrection = true,
    this.durationMinutes,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      showCorrection: json['show_correction'] ?? true,
      durationMinutes: json['duration_minutes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'show_correction': showCorrection,
      'duration_minutes': durationMinutes,
    };
  }
}
