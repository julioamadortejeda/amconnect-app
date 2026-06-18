import '../models/agent_note.dart';

abstract class NoteRepository {
  Future<List<AgentNote>> getByContactId(String contactId);
}
