import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../data/ingest_repository.dart';

export 'package:amconnect/features/feed/data/ingest_repository.dart'
    show IngestPolicyResponse, IngestKnowledgeResponse, ContactMismatchInfo;

enum IngestPhase { idle, uploading, processing, chatting, contactMismatch, success, knowledgeSuccess, error }

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
  final bool isDuplicate;
  final bool isUpdate;
  final ContactMismatchInfo? contactMismatch;
  final bool? contactMismatchResolvedToScreen;

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
    this.isDuplicate = false,
    this.isUpdate = false,
    this.contactMismatch,
    this.contactMismatchResolvedToScreen,
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
    bool? isDuplicate,
    bool? isUpdate,
    ContactMismatchInfo? contactMismatch,
    bool? contactMismatchResolvedToScreen,
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
        isDuplicate: isDuplicate ?? this.isDuplicate,
        isUpdate: isUpdate ?? this.isUpdate,
        contactMismatchResolvedToScreen: contactMismatchResolvedToScreen ?? this.contactMismatchResolvedToScreen,
        contactMismatch: contactMismatch ?? this.contactMismatch,
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

      if (result.contactMismatch != null) {
        state = state.copyWith(
          phase: IngestPhase.contactMismatch,
          sessionId: result.sessionId,
          statusMessageKey: null,
          contactMismatch: result.contactMismatch,
        );
      } else {
        _enterChatting(result);
      }
    } catch (e) {
      state = state.copyWith(
        phase: IngestPhase.error,
        error: mapApiError(e),
        statusMessageKey: null,
      );
    }
  }

  /// El asesor resolvió la pregunta de a quién asignar la póliza (ver
  /// `contactMismatch` en IngestState) — arranca el chat de confirmación
  /// normal con la decisión ya persistida en la sesión.
  Future<void> resolveContactMismatch(bool assignToScreenContact) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    state = state.copyWith(isSending: true, error: null);
    try {
      final result = await _repo.resolveContactMismatch(sessionId, assignToScreenContact);
      state = state.copyWith(contactMismatchResolvedToScreen: assignToScreenContact);
      _enterChatting(result);
    } catch (e) {
      state = state.copyWith(
        phase: IngestPhase.error,
        isSending: false,
        error: mapApiError(e),
      );
    }
  }

  void _enterChatting(IngestPolicyResponse result) {
    state = state.copyWith(
      phase: IngestPhase.chatting,
      sessionId: result.sessionId,
      documentMetadataId: result.documentMetadataId,
      extraction: result.extraction,
      messages: [IngestMessage(role: 'ai', text: result.message ?? '')],
      statusMessageKey: null,
      isDuplicate: result.isDuplicate,
      isSending: false,
    );
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
      final type = metadata?['type'];
      final isSuccess = type == 'policy_confirmed' || type == 'policy_updated';

      state = state.copyWith(
        messages: [...state.messages, IngestMessage(role: 'ai', text: result.text)],
        isSending: false,
        phase: isSuccess ? IngestPhase.success : IngestPhase.chatting,
        confirmedPolicy: isSuccess ? PolicyConfirmedData.fromMap(metadata!) : null,
        isUpdate: isSuccess && type == 'policy_updated',
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: mapApiError(e),
      );
    }
  }

  /// Cierra el sheet de ingesta sin cancelar la sesión de IA — se usa cuando
  /// el asesor pasa a corregir en el Assistant (ver AssistantResumeArgs),
  /// que retoma la MISMA sesión. A diferencia de reset(), no llama a
  /// cancelSession: la sesión sigue viva, solo cambia quién la muestra.
  /// El phase vuelve a idle para que el overlay cierre el modal y quede
  /// listo para la siguiente ingesta (ver IngestFlowOverlay).
  void closeForAssistantHandoff() {
    state = const IngestState();
  }

  Future<void> processKnowledgeFile(File file, String fileName, {String? contactId, String? policyId, String? reminderId, bool? makeGeneral}) async {
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
        reminderId: reminderId,
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
        error: mapApiError(e),
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

  Future<void> processKnowledgeText(String content, String sourceType, {String? contactId, String? policyId, String? reminderId, bool? makeGeneral}) async {
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
        reminderId: reminderId,
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
        error: mapApiError(e),
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

}

final ingestProvider = NotifierProvider<IngestNotifier, IngestState>(IngestNotifier.new);
