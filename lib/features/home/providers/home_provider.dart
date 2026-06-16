import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/reminder.dart';
import '../../../core/repositories/reminder_repository.dart';
import '../../../core/repositories/supabase_agent_repository.dart';
import '../../../core/repositories/supabase_policy_repository.dart';
import '../../../core/repositories/supabase_reminder_repository.dart';
import '../../clients/providers/clients_provider.dart';

class RemindersNotifier extends AsyncNotifier<List<Reminder>> {
  late final ReminderRepository _repo;
  RealtimeChannel? _channel;

  @override
  Future<List<Reminder>> build() async {
    _repo = ref.read(reminderRepositoryProvider);
    final initial = await _repo.getAll();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'agent_id',
        value: userId,
      );
      _channel = Supabase.instance.client
          .channel('reminders:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'reminders',
            filter: filter,
            callback: (p) => _onInsert(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'reminders',
            filter: filter,
            callback: (p) => _onUpdate(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'reminders',
            filter: filter,
            callback: (p) => _onDelete(p.oldRecord),
          )
          .subscribe((status, error) {
        debugPrint('[RT:reminders] $status $error');
      });

      ref.onDispose(() {
        _channel?.unsubscribe();
      });
    }

    return initial;
  }

  Future<void> _onInsert(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (state.asData?.value.any((r) => r.id == id) == true) return;
    final reminder = await _repo.getById(id);
    if (reminder == null) return;
    state = AsyncData([...state.requireValue, reminder]);
  }

  Future<void> _onUpdate(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (row['is_active'] == false) {
      state = AsyncData(state.requireValue.where((r) => r.id != id).toList());
      return;
    }
    final reminder = await _repo.getById(id);
    if (reminder == null) {
      state = AsyncData(state.requireValue.where((r) => r.id != id).toList());
      return;
    }
    state = AsyncData([
      for (final r in state.requireValue)
        if (r.id == id) reminder else r,
    ]);
  }

  void _onDelete(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    if (id == null) return;
    state = AsyncData(state.requireValue.where((r) => r.id != id).toList());
  }

  Future<void> updateStatus(String id, String statusCode,
      {String? comment}) async {
    final updated = await _repo.updateStatus(id, statusCode, comment: comment);
    if (updated == null) return;
    state = AsyncData([
      for (final r in state.requireValue)
        if (r.id == id) updated else r,
    ]);
  }

  Future<void> reschedule(String id, DateTime dueDate) async {
    final updated = await _repo.reschedule(id, dueDate);
    if (updated == null) return;
    state = AsyncData([
      for (final r in state.requireValue)
        if (r.id == id) updated else r,
    ]);
  }

  Future<void> updateType(String id, String typeId) async {
    final updated = await _repo.updateType(id, typeId);
    if (updated == null) return;
    state = AsyncData([
      for (final r in state.requireValue)
        if (r.id == id) updated else r,
    ]);
  }

  Future<void> updateDetails(String id,
      {String? title, String? description}) async {
    final updated =
        await _repo.updateDetails(id, title: title, description: description);
    if (updated == null) return;
    state = AsyncData([
      for (final r in state.requireValue)
        if (r.id == id) updated else r,
    ]);
  }

  Future<void> toggle(String id) async {
    final list = state.asData?.value;
    final current = list?.firstWhere(
      (r) => r.id == id,
      orElse: () => throw StateError('Reminder not found'),
    );
    if (current == null) return;
    state = AsyncData([
      for (final r in state.requireValue)
        if (r.id == id) r.copyWith(done: !r.done) else r,
    ]);
    await _repo.setDone(id, !current.done);
  }
}

final remindersProvider =
    AsyncNotifierProvider<RemindersNotifier, List<Reminder>>(
        RemindersNotifier.new);

/// Nombre del asesor autenticado desde GET /agents/me
final agentNameProvider = FutureProvider<String>((ref) {
  return ref.read(agentRepositoryProvider).getMyName();
});

/// Conteo total de pólizas del asesor — reactivo a cambios via Realtime.
class PoliciesCountNotifier extends AsyncNotifier<int> {
  RealtimeChannel? _channel;

  @override
  Future<int> build() async {
    final repo = ref.read(policyRepositoryProvider);
    final count = await repo.getCount();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _channel = Supabase.instance.client
          .channel('policies:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'policies',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'agent_id',
              value: userId,
            ),
            callback: (_) async {
              final updated = await repo.getCount();
              state = AsyncData(updated);
            },
          )
          .subscribe((status, error) {
        debugPrint('[RT:policies] $status $error');
      });

      ref.onDispose(() {
        _channel?.unsubscribe();
      });
    }

    return count;
  }
}

final policiesCountProvider = AsyncNotifierProvider<PoliciesCountNotifier, int>(
    PoliciesCountNotifier.new);

/// True cuando todos los datos del dashboard cargaron Y pasaron al menos 150ms.
final homeReadyProvider = FutureProvider<bool>((ref) async {
  await Future.wait([
    ref.watch(remindersProvider.future),
    ref.watch(agentNameProvider.future),
    ref.watch(policiesCountProvider.future),
    Future.delayed(const Duration(milliseconds: 3000)),
  ]);
  return true;
});

class HomeDashboardData {
  const HomeDashboardData({
    required this.agentName,
    required this.polizasCount,
    required this.clientsCount,
    required this.pending,
    required this.followUps,
    required this.urgentCount,
    required this.porRenovar,
  });

  final String agentName;
  final int polizasCount;
  final int clientsCount;
  final List<Reminder> pending;
  final List<Reminder> followUps;
  final int urgentCount;
  final int porRenovar;
}

/// Datos computados del dashboard — lógica de filtrado y derivación fuera de la pantalla.
final homeDashboardProvider = Provider<HomeDashboardData>((ref) {
  final reminders = ref.watch(remindersProvider).asData?.value ?? [];
  final agentName = ref.watch(agentNameProvider).asData?.value ?? '';
  final polizasCount = ref.watch(policiesCountProvider).asData?.value ?? 0;
  final clientsCount = ref.watch(clientsProvider).asData?.value.length ?? 0;

  final pending = reminders.where((r) => r.isActive).toList();
  final urgentCount = pending.where((r) => r.isUrgent).length;
  final porRenovar = pending.where((r) => r.isRenewal).length;
  final followUps = (pending.where((r) => r.isFollowUp).toList())
    ..sort((a, b) => a.date.compareTo(b.date));

  return HomeDashboardData(
    agentName: agentName,
    polizasCount: polizasCount,
    clientsCount: clientsCount,
    pending: pending,
    followUps: followUps,
    urgentCount: urgentCount,
    porRenovar: porRenovar,
  );
});
