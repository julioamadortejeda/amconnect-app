import 'dart:io';
import 'package:amconnect/core/network/api_client.dart';

class UploadUrlResponse {
  final String signedUrl;
  final String filePath;
  const UploadUrlResponse({required this.signedUrl, required this.filePath});
}

class IngestPolicyResponse {
  final String sessionId;
  final String message;
  final String documentMetadataId;
  final Map<String, dynamic> extraction;

  const IngestPolicyResponse({
    required this.sessionId,
    required this.message,
    required this.documentMetadataId,
    required this.extraction,
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
      signedUrl: data['signedUrl'] as String,
      filePath: data['filePath'] as String,
    );
  }

  Future<void> uploadToStorage(String signedUrl, File file, String mimeType) async {
    await _api.putFile(signedUrl, file, mimeType);
  }

  Future<IngestPolicyResponse> ingestPolicy({
    required String storagePath,
    required String fileName,
    String? contactId,
  }) async {
    final res = await _api.post('ai/ingest-policy', body: {
      'storagePath': storagePath,
      'fileName': fileName,
      'mimeType': 'application/pdf',
      if (contactId != null) 'contactId': contactId,
    });
    final data = res['data'] as Map<String, dynamic>;
    return IngestPolicyResponse(
      sessionId: data['sessionId'] as String,
      message: data['message'] as String,
      documentMetadataId: data['documentMetadataId'] as String,
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

  Future<void> cancelSession(String sessionId) async {
    await _api.post('ai/sessions/$sessionId/cancel');
  }
}
