class AgentNote {
  const AgentNote({
    required this.id,
    required this.contactId,
    required this.policyId,
    this.reminderId,
    required this.sourceType,
    required this.content,
    required this.createdAt,
    this.summary,
    this.storagePath,
    this.fileName,
    this.isObsolete = false,
  });

  final String id;
  final String? contactId;
  final String? policyId;
  final String? reminderId;
  final String sourceType;
  final String content;
  final String createdAt;
  final String? summary;
  final String? storagePath;
  final String? fileName;
  final bool isObsolete;

  factory AgentNote.fromJson(Map<String, dynamic> json) {
    final dm = json['document_metadata'] as Map<String, dynamic>?;
    return AgentNote(
      id: json['id'] as String,
      contactId: json['contact_id'] as String?,
      policyId: json['policy_id'] as String?,
      reminderId: json['reminder_id'] as String?,
      sourceType: json['source_type'] as String? ?? 'text',
      content: (json['content'] ?? '') as String,
      createdAt: json['created_at'] as String,
      summary: json['summary'] as String?,
      storagePath: dm?['storage_path'] as String?,
      fileName: dm?['file_name'] as String?,
      isObsolete: json['isObsolete'] as bool? ?? false,
    );
  }

  /// Notas manuales rápidas (ej. campo de texto del detalle de póliza) no
  /// generan `summary` con IA — se usa un recorte del contenido como fallback
  /// para que igual entren al contexto precargado del chat.
  Map<String, dynamic> toSlimMap() {
    return {
      'id': id,
      'summary': summary ?? _truncateContent(content),
      'sourceType': sourceType,
      'createdAt': createdAt,
      if (storagePath != null) 'storagePath': storagePath,
      if (fileName != null) 'fileName': fileName,
    };
  }
}

String _truncateContent(String content, {int maxLength = 220}) {
  final trimmed = content.trim();
  if (trimmed.length <= maxLength) return trimmed;
  return '${trimmed.substring(0, maxLength).trim()}…';
}
