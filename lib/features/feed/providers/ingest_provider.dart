import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/ingest_repository.dart';

export 'package:amconnect/features/feed/data/ingest_repository.dart'
    show IngestPolicyResponse, IngestKnowledgeResponse;

enum IngestPhase { idle, uploading, processing, chatting, success, knowledgeSuccess, error }

class IngestMessage {
  final String role; // 'user' | 'ai'
  final String text;
  const IngestMessage({required this.role, required this.text});
}

class GeneratedReminder {
  final String id;
  final String typeCode;
  final String typeName;
  final String title;
  final String dueDate;
  final bool isNew;

  const GeneratedReminder({
    required this.id,
    required this.typeCode,
    required this.typeName,
    required this.title,
    required this.dueDate,
    required this.isNew,
  });

  factory GeneratedReminder.fromMap(Map<String, dynamic> m) => GeneratedReminder(
        id: m['id'] as String,
        typeCode: m['typeCode'] as String,
        typeName: m['typeName'] as String,
        title: m['title'] as String,
        dueDate: m['dueDate'] as String,
        isNew: m['isNew'] as bool,
      );
}

class PolicyConfirmedData {
  final String policyId;
  final String? policyNumber;
  final String? carrierName;
  final String? branchName;
  final String? holderName;
  final int fieldCount;
  final List<GeneratedReminder> remindersCreated;
  final List<GeneratedReminder> remindersExisting;

  const PolicyConfirmedData({
    required this.policyId,
    this.policyNumber,
    this.carrierName,
    this.branchName,
    this.holderName,
    required this.fieldCount,
    required this.remindersCreated,
    required this.remindersExisting,
  });

  List<GeneratedReminder> get allReminders => [...remindersCreated, ...remindersExisting];

  factory PolicyConfirmedData.fromMap(Map<String, dynamic> m) {
    final reminders = m['reminders'] as Map<String, dynamic>? ?? {};
    final created = (reminders['created'] as List<dynamic>? ?? [])
        .map((r) => GeneratedReminder.fromMap(r as Map<String, dynamic>))
        .toList();
    final existing = (reminders['existing'] as List<dynamic>? ?? [])
        .map((r) => GeneratedReminder.fromMap(r as Map<String, dynamic>))
        .toList();
    return PolicyConfirmedData(
      policyId: m['policyId'] as String,
      policyNumber: m['policyNumber'] as String?,
      carrierName: m['carrierName'] as String?,
      branchName: m['branchName'] as String?,
      holderName: m['holderName'] as String?,
      fieldCount: (m['fieldCount'] as num?)?.toInt() ?? 0,
      remindersCreated: created,
      remindersExisting: existing,
    );
  }
}

class IngestState {
  final IngestPhase phase;
  final String? sessionId;
  final String? documentMetadataId;
  final Map<String, dynamic>? extraction;
  final List<IngestMessage> messages;
  final bool isSending;
  final String? error;
  final PolicyConfirmedData? confirmedPolicy;
  final String? knowledgeMessage;
  final String? statusMessageKey;
  final String? contactId;
  final String? policyId;

  const IngestState({
    this.phase = IngestPhase.idle,
    this.sessionId,
    this.documentMetadataId,
    this.extraction,
    this.messages = const [],
    this.isSending = false,
    this.error,
    this.confirmedPolicy,
    this.knowledgeMessage,
    this.statusMessageKey,
    this.contactId,
    this.policyId,
  });

  IngestState copyWith({
    IngestPhase? phase,
    String? sessionId,
    String? documentMetadataId,
    Map<String, dynamic>? extraction,
    List<IngestMessage>? messages,
    bool? isSending,
    String? error,
    PolicyConfirmedData? confirmedPolicy,
    String? knowledgeMessage,
    String? statusMessageKey,
    String? contactId,
    String? policyId,
  }) =>
      IngestState(
        phase: phase ?? this.phase,
        sessionId: sessionId ?? this.sessionId,
        documentMetadataId: documentMetadataId ?? this.documentMetadataId,
        extraction: extraction ?? this.extraction,
        messages: messages ?? this.messages,
        isSending: isSending ?? this.isSending,
        error: error,
        confirmedPolicy: confirmedPolicy ?? this.confirmedPolicy,
        knowledgeMessage: knowledgeMessage ?? this.knowledgeMessage,
        statusMessageKey: statusMessageKey ?? this.statusMessageKey,
        contactId: contactId ?? this.contactId,
        policyId: policyId ?? this.policyId,
      );
}

class IngestNotifier extends Notifier<IngestState> {
  late IngestRepository _repo;

  @override
  IngestState build() {
    _repo = IngestRepository(ref.read(apiClientProvider));
    return const IngestState();
  }

  Future<void> processPolicy(File file, String fileName, {String? contactId}) async {
    final mimeType = _mimeFromFileName(fileName);
    state = IngestState(
      phase: IngestPhase.uploading,
      statusMessageKey: 'feedStepGettingUrl',
      contactId: contactId,
    );
    try {
      final uploadUrl = await _repo.getUploadUrl(fileName, mimeType);
      await Future.delayed(const Duration(milliseconds: 600));

      state = state.copyWith(statusMessageKey: 'feedStepUploading');
      await _repo.uploadToStorage(uploadUrl.signedUrl, file, mimeType);
      await Future.delayed(const Duration(milliseconds: 600));

      state = state.copyWith(
        phase: IngestPhase.processing,
        statusMessageKey: 'feedStepProcessing',
      );

      final result = await _repo.ingestPolicy(
        storagePath: uploadUrl.filePath,
        fileName: fileName,
        mimeType: mimeType,
        contactId: contactId,
      );

      state = state.copyWith(
        phase: IngestPhase.chatting,
        sessionId: result.sessionId,
        documentMetadataId: result.documentMetadataId,
        extraction: result.extraction,
        messages: [IngestMessage(role: 'ai', text: result.message)],
        statusMessageKey: null,
      );
    } catch (e) {
      state = state.copyWith(
        phase: IngestPhase.error,
        error: e is ApiException ? _mapApiException(e) : e.toString(),
        statusMessageKey: null,
      );
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.sessionId == null) return;
    state = state.copyWith(
      messages: [...state.messages, IngestMessage(role: 'user', text: text)],
      isSending: true,
      error: null,
    );
    try {
      final result = await _repo.chat(text, state.sessionId!);
      final metadata = result.metadata;
      final isSuccess = metadata != null && metadata['type'] == 'policy_confirmed';

      PolicyConfirmedData? confirmedPolicy;
      if (isSuccess) {
        confirmedPolicy = PolicyConfirmedData.fromMap(metadata);
      }

      state = state.copyWith(
        messages: [...state.messages, IngestMessage(role: 'ai', text: result.text)],
        isSending: false,
        phase: isSuccess ? IngestPhase.success : IngestPhase.chatting,
        confirmedPolicy: confirmedPolicy,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e is ApiException ? _mapApiException(e) : e.toString(),
      );
    }
  }

  Future<void> processKnowledgeFile(File file, String fileName, {String? contactId, String? policyId, bool? makeGeneral}) async {
    final mimeType = _mimeFromFileName(fileName);
    state = IngestState(
      phase: IngestPhase.uploading,
      statusMessageKey: 'feedStepGettingUrl',
      contactId: contactId,
      policyId: policyId,
    );
    try {
      final uploadUrl = await _repo.getUploadUrl(fileName, mimeType);
      await Future.delayed(const Duration(milliseconds: 600));

      state = state.copyWith(statusMessageKey: 'feedStepUploading');
      await _repo.uploadToStorage(uploadUrl.signedUrl, file, mimeType);
      await Future.delayed(const Duration(milliseconds: 600));

      state = state.copyWith(
        phase: IngestPhase.processing,
        statusMessageKey: 'feedStepProcessing',
      );
      final result = await _repo.ingestKnowledgeFile(
        storagePath: uploadUrl.filePath,
        fileName: fileName,
        mimeType: mimeType,
        contactId: contactId,
        policyId: policyId,
        makeGeneral: makeGeneral,
      );
      state = state.copyWith(
        phase: IngestPhase.knowledgeSuccess,
        knowledgeMessage: result.message,
        statusMessageKey: null,
      );
    } catch (e) {
      state = state.copyWith(
        phase: IngestPhase.error,
        error: e is ApiException ? _mapApiException(e) : e.toString(),
        statusMessageKey: null,
      );
    }
  }

  static String _mimeFromFileName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'wav' => 'audio/wav',
      'aac' => 'audio/mp4',
      'ogg' => 'audio/ogg',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  Future<void> processKnowledgeText(String content, String sourceType, {String? contactId, String? policyId, bool? makeGeneral}) async {
    state = IngestState(
      phase: IngestPhase.processing,
      statusMessageKey: 'feedStepProcessing',
      contactId: contactId,
      policyId: policyId,
    );
    try {
      final result = await _repo.ingestKnowledgeText(
        content: content,
        sourceType: sourceType,
        contactId: contactId,
        policyId: policyId,
        makeGeneral: makeGeneral,
      );
      state = state.copyWith(
        phase: IngestPhase.knowledgeSuccess,
        knowledgeMessage: result.message,
        statusMessageKey: null,
      );
    } catch (e) {
      state = state.copyWith(
        phase: IngestPhase.error,
        error: e is ApiException ? _mapApiException(e) : e.toString(),
        statusMessageKey: null,
      );
    }
  }

  Future<void> reset() async {
    final sid = state.sessionId;
    if (sid != null) {
      try {
        await _repo.cancelSession(sid);
      } catch (_) {}
    }
    state = const IngestState();
  }

  String _mapApiException(ApiException e) {
    if (e.errorCode != null) {
      return e.errorCode!;
    }
    if (e.statusCode == 503 || e.message.contains("unavailable") || e.message.contains("high demand")) {
      return "AI_PROVIDER_BUSY";
    }
    if (e.statusCode == 401) {
      return "SESSION_EXPIRED";
    }
    if (e.statusCode == 404) {
      return "RESOURCE_NOT_FOUND";
    }

    try {
      final decoded = jsonDecode(e.message);
      if (decoded is Map) {
        if (decoded['error'] is Map) {
          return decoded['error']['message']?.toString() ?? 'Error del servidor';
        }
        return decoded['error']?.toString() ?? decoded['message']?.toString() ?? e.message;
      }
    } catch (_) {}

    return e.message;
  }
}

final ingestProvider = NotifierProvider<IngestNotifier, IngestState>(IngestNotifier.new);
