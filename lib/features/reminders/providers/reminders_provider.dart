import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/agent_note.dart';
import '../../../core/repositories/commitment_repository.dart';
import '../../../core/models/commitment.dart';
import '../../../core/models/reminder.dart';
import '../../../core/models/reminder_type.dart';
import '../../../core/network/api_client.dart';
import '../../../core/repositories/supabase_note_repository.dart';
import '../../../core/repositories/supabase_reminder_repository.dart';
import '../../home/providers/home_provider.dart';

enum RemindersViewMode { list, calendar }

/// Las dos mitades de la Agenda: lo que tiene día y lo que no.
enum AgendaTab { reminders, commitments }

/// Qué mitad de la Agenda se está viendo.
///
/// Vive en un provider y no en el `State` de la pantalla para que el dashboard
/// pueda abrir directo la pestaña de compromisos desde su "Ver todos" — con
/// estado local haría falta pasarlo por la ruta.
class AgendaTabNotifier extends Notifier<AgendaTab> {
  @override
  AgendaTab build() => AgendaTab.reminders;

  void select(AgendaTab tab) => state = tab;
}

final agendaTabProvider =
    NotifierProvider<AgendaTabNotifier, AgendaTab>(AgendaTabNotifier.new);

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
  }) =>
      RemindersState(
        filter: filter ?? this.filter,
        viewMode: viewMode ?? this.viewMode,
        selectedDate:
            clearSelectedDate ? null : selectedDate ?? this.selectedDate,
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

/// Texto de búsqueda de la agenda.
///
/// Con antirrebote porque la búsqueda la resuelve el servidor: sin él, escribir
/// "banamex" son siete peticiones y las respuestas pueden llegar desordenadas,
/// dejando en pantalla el resultado de "banam" después del de "banamex".
class AgendaSearchNotifier extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  void set(String texto) {
    _debounce?.cancel();
    final limpio = texto.trim();
    // Borrar es inmediato: el asesor quiere su lista de vuelta ya, y volver al
    // estado sin filtro no cuesta una petición.
    if (limpio.isEmpty) {
      state = '';
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => state = limpio);
  }
}

final agendaSearchProvider =
    NotifierProvider<AgendaSearchNotifier, String>(AgendaSearchNotifier.new);

/// Resultados de la búsqueda en la pestaña de recordatorios.
///
/// `autoDispose` para que al salir de la agenda no se quede en memoria el
/// resultado de una búsqueda vieja.
final reminderSearchProvider =
    FutureProvider.autoDispose<List<Reminder>>((ref) async {
  final q = ref.watch(agendaSearchProvider);
  if (q.isEmpty) return const [];
  return ref.read(reminderRepositoryProvider).search(q);
});

/// Lo mismo para la pestaña de compromisos.
final commitmentSearchProvider =
    FutureProvider.autoDispose<List<Commitment>>((ref) async {
  final q = ref.watch(agendaSearchProvider);
  if (q.isEmpty) return const [];
  return ref.read(commitmentRepositoryProvider).search(q);
});

/// Recordatorios filtrados para la vista lista.
final filteredRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider).asData?.value ?? [];
  final filter = ref.watch(remindersUiProvider).filter;
  if (filter == 'eliminados') {
    return reminders.where((r) => r.cancelled).toList();
  }
  if (filter == 'completados') {
    return reminders.where((r) => r.done).toList();
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
    return d.year == selected.year &&
        d.month == selected.month &&
        d.day == selected.day;
  }).toList();
});

/// Completados/cancelados del día seleccionado — apartado aparte en la vista
/// calendario, para no perderlos al resolverse (el asesor quiere poder ver
/// qué hizo tal día).
final selectedDayHistoryRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(remindersProvider).asData?.value ?? [];
  final selected = ref.watch(remindersUiProvider).selectedDate;
  if (selected == null) return [];
  return reminders.where((r) {
    if (r.isActive) return false;
    final d = r.dueDate;
    if (d == null) return false;
    return d.year == selected.year &&
        d.month == selected.month &&
        d.day == selected.day;
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
  }) =>
      CreateReminderState(
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

/// Notas ligadas a un recordatorio (creadas vía Share Target).
final reminderNotesProvider =
    FutureProvider.family<List<AgentNote>, String>((ref, reminderId) async {
  return ref.read(noteRepositoryProvider).getByReminderId(reminderId);
});

// Watching this provider activates Realtime for notes of a reminder —
// necesario porque la ingesta de archivo/texto con IA es asíncrona.
final reminderNotesRealtimeProvider =
    Provider.autoDispose.family<void, String>((ref, reminderId) {
  final channel = Supabase.instance.client
      .channel('notes:reminder:$reminderId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'agent_notes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'reminder_id',
          value: reminderId,
        ),
        callback: (_) => ref.invalidate(reminderNotesProvider(reminderId)),
      )
      .subscribe();
  ref.onDispose(() => channel.unsubscribe());
});

/// Mapa fecha → recordatorios activos, para pintar los puntos de prioridad
/// en el calendario.
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

/// Mapa fecha → recordatorios completados/cancelados, para el punto de
/// "carga ya resuelta" del calendario (ver [selectedDayHistoryRemindersProvider]).
final remindersHistoryByDateProvider =
    Provider<Map<DateTime, List<Reminder>>>((ref) {
  final reminders = ref.watch(remindersProvider).asData?.value ?? [];
  final map = <DateTime, List<Reminder>>{};
  for (final r in reminders) {
    if (r.isActive) continue;
    final d = r.dueDate;
    if (d == null) continue;
    final key = DateTime(d.year, d.month, d.day);
    (map[key] ??= []).add(r);
  }
  return map;
});
