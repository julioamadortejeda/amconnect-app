class ReminderComment {
  const ReminderComment({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;

  factory ReminderComment.fromJson(Map<String, dynamic> json) =>
      ReminderComment(
        id: json['id'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );
}
