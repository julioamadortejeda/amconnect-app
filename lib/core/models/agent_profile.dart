import '../utils/formatters.dart';

class AgentProfile {
  const AgentProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.plan,
    required this.isActive,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String plan;
  final bool isActive;
  final String? createdAt;

  String get initials => getInitials(fullName);

  factory AgentProfile.fromJson(Map<String, dynamic> json) => AgentProfile(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        plan: json['plan'] as String,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] as String?,
      );
}
