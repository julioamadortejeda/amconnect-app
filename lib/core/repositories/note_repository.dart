import '../models/agent_note.dart';
import '../../features/feed/data/feed_item.dart';

abstract class NoteRepository {
  Future<List<AgentNote>> getByContactId(String contactId);
  Future<List<AgentNote>> getByPolicyId(String policyId);
  Future<void> deleteNote(String noteId);
  Future<List<FeedItem>> getRecent({int limit = 20});
}
