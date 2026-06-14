class ReminderType {
  const ReminderType({required this.id, required this.code, required this.name});

  final String id;
  final String code;
  final String name;

  factory ReminderType.fromJson(Map<String, dynamic> json) => ReminderType(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
      );
}
