import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../models/reminder_type.dart';

IconData reminderIcon(String type) => switch (type) {
      'PAYMENT' => Icons.payments_outlined,
      'RENEWAL' => Icons.autorenew,
      'CANCELLATION' => Icons.block,
      'FOLLOW_UP' => Icons.flag_outlined,
      'CALL' => Icons.phone_outlined,
      'APPOINTMENT' => Icons.event_outlined,
      'ANNIVERSARY' => Icons.workspace_premium_outlined,
      'BIRTHDAY' => Icons.cake_outlined,
      _ => Icons.notifications_outlined,
    };

const _reminderTypeOrder = [
  'PAYMENT',
  'RENEWAL',
  'CANCELLATION',
  'FOLLOW_UP',
  'CALL',
  'APPOINTMENT',
  'ANNIVERSARY',
  'BIRTHDAY',
  'OTHER',
];

/// Orden fijo de tipos de recordatorio en filtros/selectores — más
/// frecuentes primero, resto del catálogo al final.
List<ReminderType> sortReminderTypes(List<ReminderType> types) {
  int priority(ReminderType t) {
    final i = _reminderTypeOrder.indexOf(t.code);
    return i == -1 ? _reminderTypeOrder.length : i;
  }

  return List.of(types)..sort((a, b) => priority(a).compareTo(priority(b)));
}

/// Orden ascendente por due_date — nulls al final (sin fecha no es "más
/// próximo"). Reusar tras cualquier mutación local de la lista (Realtime
/// insert/update) para no depender de en qué posición cayó el cambio.
int compareReminderDueDate(Reminder a, Reminder b) {
  final aDate = a.dueDate;
  final bDate = b.dueDate;
  if (aDate == null && bDate == null) return 0;
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  return aDate.compareTo(bDate);
}

enum ReminderDateBucket { overdue, today, tomorrow, thisWeek, later }

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Clasifica un recordatorio según su cercanía a hoy, para agrupar la
/// Agenda por secciones. "Esta semana" es semana calendario lunes-domingo
/// (DateTime.weekday ya numera lunes=1..domingo=7, coincide con la
/// convención MX sin config de locale) — se encoge sola cerca del fin de
/// semana en vez de desbordar a la semana siguiente.
ReminderDateBucket reminderDateBucket(DateTime? dueDate, {DateTime? now}) {
  if (dueDate == null) return ReminderDateBucket.later;
  final today = _dateOnly(now ?? DateTime.now());
  final d = _dateOnly(dueDate);
  if (d.isBefore(today)) return ReminderDateBucket.overdue;
  if (d == today) return ReminderDateBucket.today;
  final tomorrow = today.add(const Duration(days: 1));
  if (d == tomorrow) return ReminderDateBucket.tomorrow;
  final endOfWeek = today.add(Duration(days: 7 - today.weekday));
  if (!d.isAfter(endOfWeek)) return ReminderDateBucket.thisWeek;
  return ReminderDateBucket.later;
}

/// Agrupa preservando el orden ascendente que ya trae la lista (el backend
/// pagina por due_date asc) — una sola pasada, sin reordenar.
Map<ReminderDateBucket, List<Reminder>> groupRemindersByDateBucket(
  List<Reminder> reminders,
) {
  final map = <ReminderDateBucket, List<Reminder>>{};
  for (final r in reminders) {
    (map[reminderDateBucket(r.dueDate)] ??= []).add(r);
  }
  return map;
}
