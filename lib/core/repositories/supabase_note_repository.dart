import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_note.dart';
import '../network/api_client.dart';
import 'note_repository.dart';

class SupabaseNoteRepository implements NoteRepository {
  SupabaseNoteRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<AgentNote>> getByContactId(String contactId) async {
    final res = await _client.get('contacts/$contactId/notes');
    final wrapper = res['data'] as Map<String, dynamic>;
    final items = wrapper['data'] as List<dynamic>;
    return items
        .map((e) => AgentNote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AgentNote>> getByPolicyId(String policyId) async {
    final res = await _client.get('policies/$policyId/notes');
    final wrapper = res['data'] as Map<String, dynamic>;
    final items = wrapper['data'] as List<dynamic>;
    return items
        .map((e) => AgentNote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await _client.delete('notes/$noteId');
  }
}

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return SupabaseNoteRepository(ref.read(apiClientProvider));
});
