class ReminderType {
  const ReminderType({required this.code, required this.name});

  final String code;
  final String name;

  factory ReminderType.fromJson(Map<String, dynamic> json) => ReminderType(
        code: json['code'] as String,
        name: json['name'] as String,
      );
}
