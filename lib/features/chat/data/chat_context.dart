import '../../../core/models/agent_note.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/policy.dart';
import '../../../core/utils/formatters.dart';
import '../../feed/data/feed_item.dart';

class AiChatContext {
  final String type; // 'contact' | 'policy' | 'reminder'
  final String? id;
  final Map<String, dynamic> data;

  const AiChatContext({required this.type, this.id, required this.data});

  factory AiChatContext.fromContact(
    Contact contact, {
    List<Policy>? policies,
    List<AgentNote>? notes,
  }) {
    final (firstName, lastName) = splitFullName(contact.fullName);

    final slimPolicies = policies?.map((p) => p.toSlimMap()).toList();

    final slimNotes = notes
        ?.where((n) => n.summary != null)
        .map((n) => {
              'id': n.id,
              'summary': n.summary,
              'sourceType': n.sourceType,
              'createdAt': n.createdAt,
            })
        .toList();

    return AiChatContext(
      type: 'contact',
      id: contact.id,
      data: {
        'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (contact.email != null) 'email': contact.email,
        if (contact.phone != null) 'phone': contact.phone,
        if (contact.birthdate != null) 'birthday': contact.birthdate,
        if (contact.occupation != null) 'occupation': contact.occupation,
        if (contact.address != null) 'address': contact.address,
        if (contact.rfc != null) 'rfc': contact.rfc,
        if (contact.curp != null) 'curp': contact.curp,
        if (slimPolicies != null && slimPolicies.isNotEmpty) 'policies': slimPolicies,
        if (slimNotes != null && slimNotes.isNotEmpty) 'notes': slimNotes,
      },
    );
  }

  factory AiChatContext.fromKnowledgeNote(FeedItem item) {
    return AiChatContext(
      type: 'knowledge',
      id: item.id,
      data: {
        'sourceType': item.sourceType,
        'createdAt': item.createdAt,
        if (item.fileName != null) 'fileName': item.fileName,
        if (item.contactName != null) 'contactName': item.contactName,
        if (item.summary != null) 'summary': item.summary,
        if (item.content != null) 'content': item.content,
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (id != null) 'id': id,
        'data': data,
      };
}
