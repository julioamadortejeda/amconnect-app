enum ReminderPriority { urgent, warning, normal }

class Reminder {
  const Reminder({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.sub,
    required this.fecha,
    required this.hora,
    required this.hecho,
    required this.priority,
    this.contactId,
    this.dueDate,
    this.statusCode = '',
  });

  final String id;
  final String? contactId;
  final String statusCode;

  /// Código del catálogo reminder_types: PAYMENT | RENEWAL | CANCELLATION |
  /// FOLLOW_UP | CALL | APPOINTMENT | ANNIVERSARY | OTHER
  final String tipo;

  final String titulo;
  final String sub;
  final String fecha;
  final String hora;
  final bool hecho;
  final ReminderPriority priority;
  final DateTime? dueDate;

  bool get urgente => priority == ReminderPriority.urgent;

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

  // Cuando el backend envíe `priority` ('urgent' | 'warning' | 'normal')
  // lo usa directo. Si no viene, calcula con umbrales: urgent ≤3d, warning ≤7d.
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
    final contact = json['contact'] as Map<String, dynamic>?;
    final description = json['description'] as String?;

    return Reminder(
      id: json['id'] as String,
      contactId: json['contactId'] as String?,
      tipo: (json['type'] as Map<String, dynamic>?)?['code'] as String? ?? 'OTHER',
      titulo: json['title'] as String,
      sub: description?.isNotEmpty == true
          ? description!
          : contact?['fullName'] as String? ?? '',
      fecha: _formatFecha(dueDate),
      hora: _formatHora(dueDate),
      hecho: isDone,
      statusCode: statusCode,
      priority: _resolvePriority(json, dueDate, isDone),
      dueDate: dueDate != null ? DateTime.tryParse(dueDate)?.toLocal() : null,
    );
  }

  Reminder copyWith({bool? hecho, String? statusCode}) => Reminder(
        id: id,
        contactId: contactId,
        tipo: tipo,
        titulo: titulo,
        sub: sub,
        fecha: fecha,
        hora: hora,
        priority: priority,
        hecho: hecho ?? this.hecho,
        statusCode: statusCode ?? this.statusCode,
        dueDate: dueDate,
      );
}
