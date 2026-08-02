import '../../../core/models/agent_note.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/policy.dart';
import '../../../core/models/reminder.dart';
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
    final slimPolicies = policies?.map((p) => p.toSlimMap()).toList();

    final slimNotes =
        notes?.where((n) => !n.isObsolete).map((n) => n.toSlimMap()).toList();

    return AiChatContext(
      type: 'contact',
      id: contact.id,
      data: {
        'fullName': contact.fullName,
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

  factory AiChatContext.fromReminder(
    Reminder reminder, {
    List<AgentNote>? notes,
  }) {
    final slimNotes =
        notes?.where((n) => !n.isObsolete).map((n) => n.toSlimMap()).toList();

    return AiChatContext(
      type: 'reminder',
      id: reminder.id,
      data: {
        'title': reminder.title,
        'type': reminder.type,
        'statusCode': reminder.statusCode,
        if (reminder.description != null) 'description': reminder.description,
        if (reminder.dueDate != null)
          'dueDate': reminder.dueDate!.toIso8601String(),
        if (reminder.contactId != null) 'contactId': reminder.contactId,
        if (reminder.contactName != null) 'contactName': reminder.contactName,
        if (reminder.policyId != null) 'policyId': reminder.policyId,
        if (reminder.policyNumber != null)
          'policyNumber': reminder.policyNumber,
        if (reminder.comments.isNotEmpty)
          'comments': reminder.comments
              .map((c) => {
                    'content': c.content,
                    'createdAt': c.createdAt.toIso8601String(),
                  })
              .toList(),
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
