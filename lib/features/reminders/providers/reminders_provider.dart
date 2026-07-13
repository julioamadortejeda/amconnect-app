import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/reminder.dart';
import '../../../core/models/reminder_type.dart';
import '../../../core/network/api_client.dart';
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
    return reminders.where((r) => r.cancelled).toList();
  }
  final active = reminders.where((r) => r.isActive).toList();
  if (filter == 'todos') return active;
  return active.where((r) => r.type == filter).toList();
});

/// Recordatorios del día seleccionado para la vista calendario.
final selectedDayRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider).asData?.value ?? [];
  final selected = ref.watch(remindersUiProvider).selectedDate;
  if (selected == null) return [];
  return reminders.where((r) {
    if (!r.isActive) return false;
    final d = r.dueDate;
    if (d == null) return false;
    return d.year == selected.year && d.month == selected.month && d.day == selected.day;
  }).toList();
});

/// Tipos de recordatorio del catálogo.
final reminderTypesProvider = FutureProvider<List<ReminderType>>((ref) {
  ref.keepAlive();
  return ref.read(reminderRepositoryProvider).getTypes();
});

/// Estado del formulario de creación manual de recordatorios.
class CreateReminderState {
  const CreateReminderState({this.loading = false, this.error});

  final bool loading;

  /// errorCode o mensaje crudo del backend — se traduce con
  /// `context.translateError` en la pantalla.
  final String? error;

  CreateReminderState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
  }) => CreateReminderState(
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );
}

class CreateReminderNotifier extends Notifier<CreateReminderState> {
  @override
  CreateReminderState build() => const CreateReminderState();

  Future<Reminder?> submit({
    required String typeId,
    required String title,
    String? description,
    required DateTime dueDate,
    String? contactId,
    String? policyId,
    String? status,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final created = await ref.read(remindersProvider.notifier).create(
        typeId: typeId,
        title: title,
        description: description,
        dueDate: dueDate,
        contactId: contactId,
        policyId: policyId,
        status: status,
      );
      state = state.copyWith(loading: false);
      return created;
    } on ApiException catch (e) {
      state = CreateReminderState(error: e.errorCode ?? e.message);
      return null;
    }
  }

  void reset() => state = const CreateReminderState();
}

final createReminderProvider =
    NotifierProvider<CreateReminderNotifier, CreateReminderState>(
        CreateReminderNotifier.new);

/// Mapa fecha → recordatorios para pintar puntos en el calendario.
final remindersByDateProvider = Provider<Map<DateTime, List<Reminder>>>((ref) {
  final reminders = ref.watch(remindersProvider).asData?.value ?? [];
  final map = <DateTime, List<Reminder>>{};
  for (final r in reminders) {
    if (!r.isActive) continue;
    final d = r.dueDate;
    if (d == null) continue;
    final key = DateTime(d.year, d.month, d.day);
    (map[key] ??= []).add(r);
  }
  return map;
});
