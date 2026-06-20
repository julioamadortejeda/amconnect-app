import '../models/agent_note.dart';

abstract class NoteRepository {
  Future<List<AgentNote>> getByContactId(String contactId);
  Future<List<AgentNote>> getByPolicyId(String policyId);
  Future<void> deleteNote(String noteId);
}
