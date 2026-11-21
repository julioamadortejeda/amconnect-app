import '../models/agent_note.dart';
import '../../features/feed/data/feed_item.dart';

abstract class NoteRepository {
  Future<List<AgentNote>> getByContactId(String contactId);
  Future<List<AgentNote>> getByPolicyId(String policyId);
  Future<List<AgentNote>> getByReminderId(String reminderId);
  Future<void> createPolicyNote(String policyId, String content);
  Future<void> deleteNote(String noteId);
  Future<Map<String, int>> getNotesSummary();
  Future<({List<FeedItem> items, bool hasMore})> searchNotes(
      {int page = 1, int pageSize = 20, String? query});
}
