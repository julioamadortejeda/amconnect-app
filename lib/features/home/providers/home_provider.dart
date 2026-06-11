import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/models/reminder.dart';
import 'package:amconnect/core/repositories/reminder_repository.dart';
import 'package:amconnect/core/repositories/supabase_agent_repository.dart';
import 'package:amconnect/core/repositories/supabase_policy_repository.dart';
import 'package:amconnect/core/repositories/supabase_reminder_repository.dart';

class RemindersNotifier extends AsyncNotifier<List<Reminder>> {
  late final ReminderRepository _repo;

  @override
  Future<List<Reminder>> build() async {
    _repo = ref.read(reminderRepositoryProvider);
    return _repo.getAll();
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
    AsyncNotifierProvider<RemindersNotifier, List<Reminder>>(RemindersNotifier.new);

/// Nombre del asesor autenticado desde GET /agents/me
final agentNameProvider = FutureProvider<String>((ref) {
  return ref.read(agentRepositoryProvider).getMyName();
});

/// Conteo total de pólizas del asesor desde GET /policies
final policiesCountProvider = FutureProvider<int>((ref) {
  return ref.read(policyRepositoryProvider).getCount();
});
