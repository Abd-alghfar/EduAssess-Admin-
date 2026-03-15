class Profile {
  final String id;
  final String? fullName;
  final String? username;
  final String? accessKey;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.fullName,
    this.username,
    this.accessKey,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['full_name'],
      username: json['username'],
      accessKey: json['access_key'],
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'username': username,
      'access_key': accessKey,
    };
  }
}
