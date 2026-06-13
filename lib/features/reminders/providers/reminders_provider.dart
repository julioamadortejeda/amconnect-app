import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/reminder.dart';
import '../../../core/models/reminder_type.dart';
import '../../../core/repositories/supabase_reminder_repository.dart';
import '../../home/providers/home_provider.dart';

enum RemindersViewMode { list, calendar }

class RemindersState {
  const RemindersState({
    this.filter = 'todos',
    this.viewMode = RemindersViewMode.list,
    this.selectedDate,
  });

  final String filter;
  final RemindersViewMode viewMode;
  final DateTime? selectedDate;

  RemindersState copyWith({
    String? filter,
    RemindersViewMode? viewMode,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
  }) => RemindersState(
    filter: filter ?? this.filter,
    viewMode: viewMode ?? this.viewMode,
    selectedDate: clearSelectedDate ? null : selectedDate ?? this.selectedDate,
  );
}

class RemindersNotifier extends Notifier<RemindersState> {
  @override
  RemindersState build() => RemindersState(selectedDate: _today());

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setFilter(String filter) => state = state.copyWith(filter: filter);

  void toggleViewMode() => state = state.copyWith(
    viewMode: state.viewMode == RemindersViewMode.list
        ? RemindersViewMode.calendar
        : RemindersViewMode.list,
  );

  void selectDate(DateTime date) => state = state.copyWith(selectedDate: date);
}

final remindersUiProvider =
    NotifierProvider<RemindersNotifier, RemindersState>(RemindersNotifier.new);

/// Recordatorios filtrados para la vista lista.
final filteredRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider).asData?.value ?? [];
  final filter = ref.watch(remindersUiProvider).filter;
  if (filter == 'eliminados') {
    return reminders.where((r) => r.statusCode == 'CANCELLED').toList();
  }
  final active = reminders.where((r) => r.statusCode != 'CANCELLED').toList();
  if (filter == 'todos') return active;
  return active.where((r) => r.type == filter).toList();
});

/// Recordatorios del día seleccionado para la vista calendario.
final selectedDayRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider).asData?.value ?? [];
  final selected = ref.watch(remindersUiProvider).selectedDate;
  if (selected == null) return [];
  return reminders.where((r) {
    final d = r.dueDate;
    if (d == null) return false;
    return d.year == selected.year && d.month == selected.month && d.day == selected.day;
  }).toList();
});

/// Tipos de recordatorio del catálogo.
final reminderTypesProvider = FutureProvider<List<ReminderType>>((ref) {
  return ref.read(reminderRepositoryProvider).getTypes();
});

/// Mapa fecha → recordatorios para pintar puntos en el calendario.
final remindersByDateProvider = Provider<Map<DateTime, List<Reminder>>>((ref) {
  final reminders = ref.watch(remindersProvider).asData?.value ?? [];
  final map = <DateTime, List<Reminder>>{};
  for (final r in reminders) {
    final d = r.dueDate;
    if (d == null) continue;
    final key = DateTime(d.year, d.month, d.day);
    (map[key] ??= []).add(r);
  }
  return map;
});
