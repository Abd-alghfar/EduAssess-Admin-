class ChatMessage {
  final String id;
  final String senderId;
  final String? content;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    this.content,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
  });

  // Check if message is from the instructor
  bool get isFromTeacher => content?.startsWith('[INSTRUCTOR]') ?? false;

  // Get display content without the [INSTRUCTOR] prefix
  String get displayContent {
    if (content == null) return '';
    if (isFromTeacher) {
      return content!.replaceFirst('[INSTRUCTOR]', '').trim();
    }
    return content!;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['sender_id'],
      content: json['content'],
      imageUrl: json['image_url'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'content': content,
      'image_url': imageUrl,
      'is_read': isRead,
    };
  }
}
