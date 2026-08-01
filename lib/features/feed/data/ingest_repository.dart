import 'dart:io';
import '../../../core/network/api_client.dart';

class UploadUrlResponse {
  final String signedUrl;
  final String filePath;
  const UploadUrlResponse({required this.signedUrl, required this.filePath});
}

class ContactMismatchInfo {
  final String screenContactName;
  final String detectedContactName;
  const ContactMismatchInfo({
    required this.screenContactName,
    required this.detectedContactName,
  });
}

class IngestPolicyResponse {
  final String sessionId;
  final String? message;
  final String? documentMetadataId;
  final Map<String, dynamic>? extraction;
  final bool isDuplicate;
  final ContactMismatchInfo? contactMismatch;

  const IngestPolicyResponse({
    required this.sessionId,
    this.message,
    this.documentMetadataId,
    this.extraction,
    this.isDuplicate = false,
    this.contactMismatch,
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
    return _parseIngestPolicyResponse(res['data'] as Map<String, dynamic>);
  }

  Future<IngestPolicyResponse> resolveContactMismatch(
    String sessionId,
    bool assignToScreenContact,
  ) async {
    final res = await _api.post(
      'ai/sessions/$sessionId/resolve-contact-mismatch',
      body: {'assignToScreenContact': assignToScreenContact},
    );
    return _parseIngestPolicyResponse(res['data'] as Map<String, dynamic>);
  }

  IngestPolicyResponse _parseIngestPolicyResponse(Map<String, dynamic> data) {
    final mismatchData = data['contactMismatch'] as Map<String, dynamic>?;
    return IngestPolicyResponse(
      sessionId: data['sessionId'] as String,
      message: data['message'] as String?,
      documentMetadataId: data['documentMetadataId'] as String?,
      extraction: data['extraction'] as Map<String, dynamic>?,
      isDuplicate: data['isDuplicate'] as bool? ?? false,
      contactMismatch: mismatchData != null
          ? ContactMismatchInfo(
              screenContactName: mismatchData['screenContactName'] as String,
              detectedContactName: mismatchData['detectedContactName'] as String,
            )
          : null,
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
    String? reminderId,
    bool? makeGeneral,
  }) async {
    final res = await _api.post('ai/ingest', body: {
      'storagePath': storagePath,
      'fileName': fileName,
      'mimeType': mimeType,
      if (contactId != null) 'contactId': contactId,
      if (policyId != null) 'policyId': policyId,
      if (reminderId != null) 'reminderId': reminderId,
      if (makeGeneral != null) 'makeGeneral': makeGeneral,
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
    String? reminderId,
    bool? makeGeneral,
    bool isClientNote = false,
  }) async {
    final res = await _api.post('ai/ingest-text', body: {
      'content': content,
      'sourceType': sourceType,
      if (contactId != null) 'contactId': contactId,
      if (policyId != null) 'policyId': policyId,
      if (reminderId != null) 'reminderId': reminderId,
      if (makeGeneral != null) 'makeGeneral': makeGeneral,
      if (isClientNote) 'isClientNote': true,
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
