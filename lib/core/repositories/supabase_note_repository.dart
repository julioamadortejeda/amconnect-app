import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_note.dart';
import '../network/api_client.dart';
import '../../features/feed/data/feed_item.dart';
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

  @override
  Future<List<FeedItem>> getRecent({int limit = 20}) async {
    final res = await _client.get('notes/recent?limit=$limit');
    final wrapper = res['data'] as Map<String, dynamic>;
    final items = wrapper['data'] as List<dynamic>;
    return items
        .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, int>> getNotesSummary() async {
    final res = await _client.get('notes/summary');
    final wrapper = res['data'] as Map<String, dynamic>;
    return wrapper.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  @override
  Future<List<FeedItem>> searchNotes({int limit = 20, int offset = 0, String? query}) async {
    final buf = StringBuffer('notes/search?limit=$limit&offset=$offset');
    if (query != null && query.trim().isNotEmpty) {
      buf.write('&search=${Uri.encodeComponent(query)}');
    }
    final res = await _client.get(buf.toString());
    final wrapper = res['data'] as Map<String, dynamic>;
    final items = wrapper['data'] as List<dynamic>;
    return items
        .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return SupabaseNoteRepository(ref.read(apiClientProvider));
});
