import '../../../core/models/agent_note.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/policy.dart';

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
    final parts = contact.fullName.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : contact.fullName;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;

    final slimPolicies = policies
        ?.map((p) => {
              'id': p.id,
              if (p.policyNumber != null) 'policyNumber': p.policyNumber,
              if (p.carrierName != '—') 'carrier': p.carrierName,
              if (p.branchName != '—') 'branch': p.branchName,
              if (p.productName != '—') 'product': p.productName,
              if (p.premium != null) 'premium': p.premium,
              'currency': p.currencyCode,
              if (p.statusCode.isNotEmpty) 'status': p.statusCode,
              if (p.startDate != null) 'startDate': p.startDate,
              if (p.endDate != null) 'endDate': p.endDate,
              if (p.renewalDate != null) 'renewalDate': p.renewalDate,
              if (p.nextPaymentDate != null) 'nextPaymentDate': p.nextPaymentDate,
            })
        .toList();

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

  Map<String, dynamic> toJson() => {
        'type': type,
        if (id != null) 'id': id,
        'data': data,
      };
}
