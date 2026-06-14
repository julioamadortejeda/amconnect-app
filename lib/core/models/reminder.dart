import 'reminder_comment.dart';

enum ReminderPriority { urgent, warning, normal }

class Reminder {
  const Reminder({
    required this.id,
    required this.type,
    required this.typeId,
    required this.typeName,
    required this.title,
    required this.sub,
    required this.date,
    required this.time,
    required this.done,
    required this.cancelled,
    required this.priority,
    required this.comments,
    this.contactId,
    this.contactName,
    this.policyId,
    this.policyNumber,
    this.description,
    this.dueDate,
    this.createdAt,
    this.statusCode = '',
  });

  final String id;
  final String typeId;
  final String? contactId;
  final String? contactName;
  final String? policyId;
  final String? policyNumber;
  final String? description;
  final String statusCode;
  final List<ReminderComment> comments;

  /// Código del catálogo reminder_types: PAYMENT | RENEWAL | CANCELLATION |
  /// FOLLOW_UP | CALL | APPOINTMENT | ANNIVERSARY | OTHER
  final String type;

  /// Nombre en inglés del tipo tal como viene del backend
  final String typeName;

  final String title;
  final String sub;
  final String date;
  final String time;
  final bool done;
  final bool cancelled;
  final ReminderPriority priority;
  final DateTime? dueDate;
  final DateTime? createdAt;

  bool get isUrgent   => priority == ReminderPriority.urgent;
  bool get isActive   => !done && !cancelled;
  bool get isRenewal  => type == 'RENEWAL';
  bool get isFollowUp => type == 'FOLLOW_UP';
  bool get isPayment  => type == 'PAYMENT';

  static const _months = [
    'ene','feb','mar','abr','may','jun',
    'jul','ago','sep','oct','nov','dic',
  ];

  static String _formatFecha(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '—';
    final dt = DateTime.tryParse(isoDate)?.toLocal();
    if (dt == null) return '—';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Hoy';
    if (d == today.add(const Duration(days: 1))) return 'Mañana';
    return '${dt.day} ${_months[dt.month - 1]}';
  }

  static String _formatHora(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '—';
    final dt = DateTime.tryParse(isoDate)?.toLocal();
    if (dt == null || (dt.hour == 0 && dt.minute == 0)) return '—';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static ReminderPriority _resolvePriority(
    Map<String, dynamic> json,
    String? dueDate,
    bool isDone,
  ) {
    if (isDone) return ReminderPriority.normal;

    final fromBackend = json['priority'] as String?;
    if (fromBackend != null) {
      return switch (fromBackend) {
        'urgent'  => ReminderPriority.urgent,
        'warning' => ReminderPriority.warning,
        _         => ReminderPriority.normal,
      };
    }

    final dt = dueDate != null ? DateTime.tryParse(dueDate)?.toLocal() : null;
    if (dt == null) return ReminderPriority.normal;
    final now = DateTime.now();
    if (dt.isBefore(now.add(const Duration(days: 3)))) return ReminderPriority.urgent;
    if (dt.isBefore(now.add(const Duration(days: 7)))) return ReminderPriority.warning;
    return ReminderPriority.normal;
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final dueDate = json['dueDate'] as String?;
    final statusMap = json['status'] as Map<String, dynamic>?;
    final statusCode = statusMap?['code'] as String? ?? '';
    final isDone = statusCode == 'DONE' || (json['isDone'] as bool? ?? false);
    final isCancelled = statusCode == 'CANCELLED';
    final contact = json['contact'] as Map<String, dynamic>?;
    final description = json['description'] as String?;
    final typeMap = json['type'] as Map<String, dynamic>?;
    final policyMap = json['policy'] as Map<String, dynamic>?;
    final commentsList = json['comments'] as List<dynamic>?;
    final contactName = contact?['fullName'] as String?;

    return Reminder(
      id: json['id'] as String,
      typeId: typeMap?['id'] as String? ?? json['typeId'] as String? ?? '',
      contactId: json['contactId'] as String?,
      contactName: contactName,
      policyId: json['policyId'] as String?,
      policyNumber: policyMap?['policyNumber'] as String?,
      description: description,
      type: typeMap?['code'] as String? ?? 'OTHER',
      typeName: typeMap?['name'] as String? ?? typeMap?['code'] as String? ?? 'Other',
      title: json['title'] as String,
      sub: description?.isNotEmpty == true
          ? description!
          : contactName ?? '',
      date: _formatFecha(dueDate),
      time: _formatHora(dueDate),
      done: isDone,
      cancelled: isCancelled,
      statusCode: statusCode,
      priority: _resolvePriority(json, dueDate, isDone),
      dueDate: dueDate != null ? DateTime.tryParse(dueDate)?.toLocal() : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)?.toLocal()
          : null,
      comments: commentsList
              ?.map((e) => ReminderComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Reminder copyWith({bool? done, bool? cancelled, String? statusCode}) => Reminder(
        id: id,
        typeId: typeId,
        contactId: contactId,
        contactName: contactName,
        policyId: policyId,
        policyNumber: policyNumber,
        description: description,
        type: type,
        typeName: typeName,
        title: title,
        sub: sub,
        date: date,
        time: time,
        priority: priority,
        done: done ?? this.done,
        cancelled: cancelled ?? this.cancelled,
        statusCode: statusCode ?? this.statusCode,
        dueDate: dueDate,
        createdAt: createdAt,
        comments: comments,
      );
}
