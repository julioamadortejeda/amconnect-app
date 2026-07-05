import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/agent_note.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/policy.dart';
import '../../../core/models/reminder.dart';
import '../../../core/repositories/contact_repository.dart';
import '../../../core/repositories/supabase_contact_repository.dart';
import '../../../core/repositories/supabase_note_repository.dart';
import '../../../core/repositories/policy_repository.dart';
import '../../../core/repositories/supabase_policy_repository.dart';
import '../../chat/data/chat_context.dart';
import '../../home/providers/home_provider.dart';

class _SearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final clientSearchProvider =
    NotifierProvider<_SearchNotifier, String>(_SearchNotifier.new);

class _PolicySearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final policySearchProvider =
    NotifierProvider<_PolicySearchNotifier, String>(_PolicySearchNotifier.new);

class ClientsNotifier extends AsyncNotifier<List<Contact>> {
  late final ContactRepository _repo;
  RealtimeChannel? _channel;

  @override
  Future<List<Contact>> build() async {
    _repo = ref.read(contactRepositoryProvider);
    final initial = await _repo.getAll();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'agent_id',
        value: userId,
      );
      _channel = Supabase.instance.client
          .channel('contacts:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'contacts',
            filter: filter,
            callback: (p) => _onInsert(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'contacts',
            filter: filter,
            callback: (p) => _onUpdate(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'contacts',
            filter: filter,
            callback: (p) => _onDelete(p.oldRecord),
          )
          .subscribe((status, error) {
            debugPrint('[RT:contacts] $status $error');
          });

      ref.onDispose(() { _channel?.unsubscribe(); });
    }

    return initial;
  }

  Future<void> _onInsert(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (state.asData?.value.any((c) => c.id == id) == true) return;
    try {
      final contact = await _repo.getById(id);
      state = AsyncData([...state.requireValue, contact]);
    } catch (_) {}
  }

  Future<void> _onUpdate(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (row['is_active'] == false) {
      state = AsyncData(state.requireValue.where((c) => c.id != id).toList());
      return;
    }
    try {
      final contact = await _repo.getById(id);
      state = AsyncData([
        for (final c in state.requireValue) if (c.id == id) contact else c,
      ]);
    } catch (_) {}
  }

  void _onDelete(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    if (id == null) return;
    state = AsyncData(state.requireValue.where((c) => c.id != id).toList());
  }
}

final clientsProvider =
    AsyncNotifierProvider<ClientsNotifier, List<Contact>>(ClientsNotifier.new);

class PoliciesNotifier extends AsyncNotifier<List<Policy>> {
  late final PolicyRepository _repo;
  RealtimeChannel? _channel;

  @override
  Future<List<Policy>> build() async {
    _repo = ref.read(policyRepositoryProvider);
    final initial = await _repo.getAll();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'agent_id',
        value: userId,
      );
      _channel = Supabase.instance.client
          .channel('policies:global:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'policies',
            filter: filter,
            callback: (p) => _onInsert(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'policies',
            filter: filter,
            callback: (p) => _onUpdate(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'policies',
            filter: filter,
            callback: (p) => _onDelete(p.oldRecord),
          )
          .subscribe((status, error) {
            debugPrint('[RT:policies_global] $status $error');
          });

      ref.onDispose(() { _channel?.unsubscribe(); });
    }

    return initial;
  }

  Future<void> _onInsert(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (state.asData?.value.any((p) => p.id == id) == true) return;
    try {
      final policy = await _repo.getById(id);
      state = AsyncData([...state.requireValue, policy]);
    } catch (_) {}
  }

  Future<void> _onUpdate(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    try {
      final policy = await _repo.getById(id);
      state = AsyncData([
        for (final p in state.requireValue) if (p.id == id) policy else p,
      ]);
    } catch (_) {}
  }

  void _onDelete(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    if (id == null) return;
    state = AsyncData(state.requireValue.where((p) => p.id != id).toList());
  }
}

final policiesProvider =
    AsyncNotifierProvider<PoliciesNotifier, List<Policy>>(PoliciesNotifier.new);

/// Agrupa recordatorios activos por contactId — sin red, derivado de remindersProvider.
final contactRemindersMapProvider = Provider<Map<String, List<Reminder>>>((ref) {
  final reminders = ref.watch(remindersProvider).asData?.value ?? [];
  final map = <String, List<Reminder>>{};
  for (final r in reminders) {
    if (!r.isActive) continue;
    final cid = r.contactId;
    if (cid == null) continue;
    (map[cid] ??= []).add(r);
  }
  return map;
});

final contactDetailProvider =
    FutureProvider.family<Contact, String>((ref, id) async {
  return ref.read(contactRepositoryProvider).getById(id);
});

final contactPoliciesProvider =
    FutureProvider.family<List<Policy>, String>((ref, contactId) async {
  return ref.read(policyRepositoryProvider).getByContactId(contactId);
});

// Watching this provider activates Realtime for policies of a contact.
// autoDispose ensures the channel closes when the screen is popped.
final contactPoliciesRealtimeProvider =
    Provider.autoDispose.family<void, String>((ref, contactId) {
  final channel = Supabase.instance.client
      .channel('policies:contact:$contactId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'policies',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'contact_id',
          value: contactId,
        ),
        callback: (_) => ref.invalidate(contactPoliciesProvider(contactId)),
      )
      .subscribe();
  ref.onDispose(() => channel.unsubscribe());
});

final contactNotesProvider =
    FutureProvider.family<List<AgentNote>, String>((ref, contactId) async {
  return ref.read(noteRepositoryProvider).getByContactId(contactId);
});

final policyNotesProvider =
    FutureProvider.family<List<AgentNote>, String>((ref, policyId) async {
  return ref.read(noteRepositoryProvider).getByPolicyId(policyId);
});

// Watching this provider activates Realtime for notes of a contact.
final contactNotesRealtimeProvider =
    Provider.autoDispose.family<void, String>((ref, contactId) {
  final channel = Supabase.instance.client
      .channel('notes:contact:$contactId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'agent_notes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'contact_id',
          value: contactId,
        ),
        callback: (_) => ref.invalidate(contactNotesProvider(contactId)),
      )
      .subscribe();
  ref.onDispose(() => channel.unsubscribe());
});

/// Contexto de IA listo para enviar al chat, construido con los datos
/// ya cargados en pantalla (contacto + pólizas + notas).
final contactAiContextProvider =
    Provider.family<AiChatContext, String>((ref, contactId) {
  final contact = ref.watch(clientsProvider).asData?.value
          .where((c) => c.id == contactId)
          .firstOrNull ??
      ref.watch(contactDetailProvider(contactId)).asData?.value;

  if (contact == null) {
    return AiChatContext(type: 'contact', id: contactId, data: {});
  }

  final policies = ref.watch(contactPoliciesProvider(contactId)).asData?.value;
  final notes = ref.watch(contactNotesProvider(contactId)).asData?.value;

  return AiChatContext.fromContact(contact, policies: policies, notes: notes);
});

