class AgentNote {
  const AgentNote({
    required this.id,
    required this.contactId,
    required this.policyId,
    required this.sourceType,
    required this.content,
    required this.createdAt,
    this.summary,
    this.storagePath,
    this.fileName,
  });

  final String id;
  final String? contactId;
  final String? policyId;
  final String sourceType;
  final String content;
  final String createdAt;
  final String? summary;
  final String? storagePath;
  final String? fileName;

  factory AgentNote.fromJson(Map<String, dynamic> json) {
    final dm = json['document_metadata'] as Map<String, dynamic>?;
    return AgentNote(
      id: json['id'] as String,
      contactId: json['contact_id'] as String?,
      policyId: json['policy_id'] as String?,
      sourceType: json['source_type'] as String? ?? 'text',
      content: (json['content'] ?? '') as String,
      createdAt: json['created_at'] as String,
      summary: json['summary'] as String?,
      storagePath: dm?['storage_path'] as String?,
      fileName: dm?['file_name'] as String?,
    );
  }
}
