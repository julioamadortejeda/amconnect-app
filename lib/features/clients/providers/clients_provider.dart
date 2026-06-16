import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/policy.dart';
import '../../../core/repositories/contact_repository.dart';
import '../../../core/repositories/supabase_contact_repository.dart';
import '../../../core/repositories/supabase_policy_repository.dart';

class _SearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final clientSearchProvider =
    NotifierProvider<_SearchNotifier, String>(_SearchNotifier.new);

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

final contactDetailProvider =
    FutureProvider.family<Contact, String>((ref, id) async {
  return ref.read(contactRepositoryProvider).getById(id);
});

final contactPoliciesProvider =
    FutureProvider.family<List<Policy>, String>((ref, contactId) async {
  return ref.read(policyRepositoryProvider).getByContactId(contactId);
});

class AgentNote {
  const AgentNote({
    required this.id,
    required this.contactId,
    required this.policyId,
    required this.sourceType,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String? contactId;
  final String? policyId;
  final String sourceType;
  final String content;
  final String createdAt;

  factory AgentNote.fromJson(Map<String, dynamic> json) => AgentNote(
        id: json['id'] as String,
        contactId: json['contact_id'] as String?,
        policyId: json['policy_id'] as String?,
        sourceType: json['source_type'] as String? ?? 'text',
        content: (json['content'] ?? json['ai_content'] ?? '') as String,
        createdAt: json['created_at'] as String,
      );
}

final contactNotesProvider =
    FutureProvider.family<List<AgentNote>, String>((ref, contactId) async {
  final res = await Supabase.instance.client
      .from('agent_notes')
      .select('*')
      .eq('contact_id', contactId)
      .eq('is_active', true)
      .order('created_at', ascending: false);
  
  final list = res as List<dynamic>? ?? [];
  return list.map((e) => AgentNote.fromJson(e as Map<String, dynamic>)).toList();
});

