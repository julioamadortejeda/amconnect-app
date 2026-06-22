import 'dart:io';
import '../../../core/network/api_client.dart';

class UploadUrlResponse {
  final String signedUrl;
  final String filePath;
  const UploadUrlResponse({required this.signedUrl, required this.filePath});
}

class IngestPolicyResponse {
  final String sessionId;
  final String message;
  final String? documentMetadataId;
  final Map<String, dynamic> extraction;

  const IngestPolicyResponse({
    required this.sessionId,
    required this.message,
    this.documentMetadataId,
    required this.extraction,
  });
}

class IngestKnowledgeResponse {
  final String? noteId;
  final String sessionId;
  final String message;
  const IngestKnowledgeResponse({
    this.noteId,
    required this.sessionId,
    required this.message,
  });
}

class IngestRepository {
  final ApiClient _api;
  IngestRepository(this._api);

  Future<UploadUrlResponse> getUploadUrl(String fileName, String mimeType) async {
    final res = await _api.get(
      'ai/upload-url?fileName=${Uri.encodeComponent(fileName)}&mimeType=${Uri.encodeComponent(mimeType)}',
    );
    final data = res['data'] as Map<String, dynamic>;
    return UploadUrlResponse(
      signedUrl: data['uploadUrl'] as String,
      filePath: data['storagePath'] as String,
    );
  }

  Future<void> uploadToStorage(String signedUrl, File file, String mimeType) async {
    await _api.putFile(signedUrl, file, mimeType);
  }

  Future<IngestPolicyResponse> ingestPolicy({
    required String storagePath,
    required String fileName,
    required String mimeType,
    String? contactId,
  }) async {
    final res = await _api.post('ai/ingest-policy', body: {
      'storagePath': storagePath,
      'fileName': fileName,
      'mimeType': mimeType,
      if (contactId != null) 'contactId': contactId,
    });
    final data = res['data'] as Map<String, dynamic>;
    return IngestPolicyResponse(
      sessionId: data['sessionId'] as String,
      message: data['message'] as String,
      documentMetadataId: data['documentMetadataId'] as String?,
      extraction: data['extraction'] as Map<String, dynamic>,
    );
  }

  Future<({String text, String sessionId, Map<String, dynamic>? metadata})> chat(
    String message,
    String sessionId,
  ) async {
    final res = await _api.post('ai/chat', body: {
      'message': message,
      'sessionId': sessionId,
    });
    final data = res['data'] as Map<String, dynamic>;
    return (
      text: data['text'] as String,
      sessionId: data['sessionId'] as String,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Future<IngestKnowledgeResponse> ingestKnowledgeFile({
    required String storagePath,
    required String fileName,
    required String mimeType,
    String? contactId,
    String? policyId,
  }) async {
    final res = await _api.post('ai/ingest', body: {
      'storagePath': storagePath,
      'fileName': fileName,
      'mimeType': mimeType,
      if (contactId != null) 'contactId': contactId,
      if (policyId != null) 'policyId': policyId,
    });
    final data = res['data'] as Map<String, dynamic>;
    return IngestKnowledgeResponse(
      noteId: data['noteId'] as String?,
      sessionId: data['sessionId'] as String,
      message: data['message'] as String,
    );
  }

  Future<IngestKnowledgeResponse> ingestKnowledgeText({
    required String content,
    required String sourceType,
    String? contactId,
    String? policyId,
  }) async {
    final res = await _api.post('ai/ingest-text', body: {
      'content': content,
      'sourceType': sourceType,
      if (contactId != null) 'contactId': contactId,
      if (policyId != null) 'policyId': policyId,
    });
    final data = res['data'] as Map<String, dynamic>;
    return IngestKnowledgeResponse(
      noteId: data['noteId'] as String?,
      sessionId: data['sessionId'] as String,
      message: data['message'] as String,
    );
  }

  Future<void> cancelSession(String sessionId) async {
    await _api.post('ai/sessions/$sessionId/cancel');
  }
}
