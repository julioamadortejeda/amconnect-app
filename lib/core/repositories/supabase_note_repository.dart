import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_note.dart';
import '../network/api_client.dart';
import '../network/api_envelope.dart';
import '../../features/feed/data/feed_item.dart';
import 'note_repository.dart';

class SupabaseNoteRepository implements NoteRepository {
  SupabaseNoteRepository(this._client);
  final ApiClient _client;

  /// Las pantallas de detalle muestran todas las notas de la entidad: se
  /// recorren las páginas del listado en vez de pedir "todo" de una vez.
  Future<List<AgentNote>> _all(String path) => fetchAllPages(
        fetch: (page, size) => _client.get('$path?page=$page&pageSize=$size'),
        parse: AgentNote.fromJson,
        idOf: (n) => n.id,
      );

  @override
  Future<List<AgentNote>> getByContactId(String contactId) =>
      _all('contacts/$contactId/notes');

  @override
  Future<List<AgentNote>> getByPolicyId(String policyId) =>
      _all('policies/$policyId/notes');

  @override
  Future<List<AgentNote>> getByReminderId(String reminderId) =>
      _all('reminders/$reminderId/notes');

  @override
  Future<void> createPolicyNote(String policyId, String content) async {
    await _client.post('policies/$policyId/notes', body: {'content': content});
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await _client.delete('notes/$noteId');
  }

  @override
  Future<Map<String, int>> getNotesSummary() async {
    final res = await _client.get('notes/summary');
    return unwrapData(res)
        .map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  @override
  Future<({List<FeedItem> items, bool hasMore})> searchNotes({
    int page = 1,
    int pageSize = 20,
    String? query,
  }) async {
    final buf = StringBuffer('notes/search?page=$page&pageSize=$pageSize');
    if (query != null && query.trim().isNotEmpty) {
      buf.write('&search=${Uri.encodeComponent(query)}');
    }
    final res = await _client.get(buf.toString());
    final result = PageResponse.fromEnvelope(res, FeedItem.fromJson);
    return (items: result.items, hasMore: result.hasMore);
  }
}

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return SupabaseNoteRepository(ref.read(apiClientProvider));
});
