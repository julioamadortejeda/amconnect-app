import 'package:flutter/material.dart';
import '../models/reminder_type.dart';

IconData reminderIcon(String type) => switch (type) {
      'PAYMENT' => Icons.payments_outlined,
      'RENEWAL' => Icons.autorenew,
      'CANCELLATION' => Icons.block,
      'FOLLOW_UP' => Icons.flag_outlined,
      'CALL' => Icons.phone_outlined,
      'APPOINTMENT' => Icons.event_outlined,
      'ANNIVERSARY' => Icons.cake,
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
