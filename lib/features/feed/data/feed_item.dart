class FeedItem {
  const FeedItem({
    required this.id,
    required this.sourceType,
    required this.createdAt,
    this.contactId,
    this.policyId,
    this.contactName,
    this.fileName,
    this.storagePath,
    this.content,
    this.summary,
  });

  final String id;
  final String? contactId;
  final String? policyId;
  final String sourceType;
  final String createdAt;
  final String? contactName;
  final String? fileName;
  final String? storagePath;
  final String? content;
  final String? summary;

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    final dm = json['document_metadata'] as Map<String, dynamic>?;
    final ct = json['contacts'] as Map<String, dynamic>?;
    return FeedItem(
      id: json['id'] as String,
      contactId: json['contact_id'] as String?,
      policyId: json['policy_id'] as String?,
      sourceType: json['source_type'] as String? ?? 'doc',
      createdAt: json['created_at'] as String,
      contactName: ct?['full_name'] as String?,
      fileName: dm?['file_name'] as String?,
      storagePath: dm?['storage_path'] as String?,
      content: json['content'] as String?,
      summary: json['summary'] as String?,
    );
  }
}
