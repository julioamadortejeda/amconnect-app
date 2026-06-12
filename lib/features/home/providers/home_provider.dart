import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/models/reminder.dart';
import 'package:amconnect/core/repositories/reminder_repository.dart';
import 'package:amconnect/core/repositories/supabase_agent_repository.dart';
import 'package:amconnect/core/repositories/supabase_policy_repository.dart';
import 'package:amconnect/core/repositories/supabase_reminder_repository.dart';
import 'package:amconnect/features/clients/providers/clients_provider.dart';

class RemindersNotifier extends AsyncNotifier<List<Reminder>> {
  late final ReminderRepository _repo;

  @override
  Future<List<Reminder>> build() async {
    _repo = ref.read(reminderRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> updateStatus(String id, String statusCode, {String? comment}) async {
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

  Future<void> toggle(String id) async {
    final list = state.asData?.value;
    final current = list?.firstWhere(
      (r) => r.id == id,
      orElse: () => throw StateError('Reminder not found'),
    );
    if (current == null) return;
    state = AsyncData([
      for (final r in state.requireValue)
        if (r.id == id) r.copyWith(hecho: !r.hecho) else r,
    ]);
    await _repo.setDone(id, !current.hecho);
  }
}

final remindersProvider =
    AsyncNotifierProvider<RemindersNotifier, List<Reminder>>(
        RemindersNotifier.new);

/// Nombre del asesor autenticado desde GET /agents/me
final agentNameProvider = FutureProvider<String>((ref) {
  return ref.read(agentRepositoryProvider).getMyName();
});

/// Conteo total de pólizas del asesor desde GET /policies
final policiesCountProvider = FutureProvider<int>((ref) {
  return ref.read(policyRepositoryProvider).getCount();
});

/// True cuando todos los datos del dashboard cargaron Y pasaron al menos 150ms.
final homeReadyProvider = FutureProvider<bool>((ref) async {
  await Future.wait([
    ref.watch(remindersProvider.future),
    ref.watch(agentNameProvider.future),
    ref.watch(policiesCountProvider.future),
    Future.delayed(const Duration(milliseconds: 150)),
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
  final reminders    = ref.watch(remindersProvider).asData?.value ?? [];
  final agentName    = ref.watch(agentNameProvider).asData?.value ?? '';
  final polizasCount = ref.watch(policiesCountProvider).asData?.value ?? 0;
  final clientsCount = ref.watch(clientsProvider).asData?.value.length ?? 0;

  final pending      = reminders.where((r) => !r.hecho).toList();
  final urgentCount  = pending.where((r) => r.urgente).length;
  final porRenovar   = pending.where((r) => r.tipo == 'RENEWAL').length;
  final followUps    = (pending.where((r) => r.tipo == 'FOLLOW_UP').toList())
    ..sort((a, b) => a.fecha.compareTo(b.fecha));

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
