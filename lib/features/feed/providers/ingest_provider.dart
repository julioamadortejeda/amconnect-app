import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/network/api_client.dart';
import 'package:amconnect/features/feed/data/ingest_repository.dart';

export 'package:amconnect/features/feed/data/ingest_repository.dart' show IngestPolicyResponse;

enum IngestPhase { idle, uploading, processing, chatting, success, error }

class IngestMessage {
  final String role; // 'user' | 'ai'
  final String text;
  const IngestMessage({required this.role, required this.text});
}

class IngestState {
  final IngestPhase phase;
  final String? sessionId;
  final String? documentMetadataId;
  final Map<String, dynamic>? extraction;
  final List<IngestMessage> messages;
  final bool isSending;
  final String? error;

  const IngestState({
    this.phase = IngestPhase.idle,
    this.sessionId,
    this.documentMetadataId,
    this.extraction,
    this.messages = const [],
    this.isSending = false,
    this.error,
  });

  IngestState copyWith({
    IngestPhase? phase,
    String? sessionId,
    String? documentMetadataId,
    Map<String, dynamic>? extraction,
    List<IngestMessage>? messages,
    bool? isSending,
    String? error,
  }) => IngestState(
    phase: phase ?? this.phase,
    sessionId: sessionId ?? this.sessionId,
    documentMetadataId: documentMetadataId ?? this.documentMetadataId,
    extraction: extraction ?? this.extraction,
    messages: messages ?? this.messages,
    isSending: isSending ?? this.isSending,
    error: error,
  );
}

class IngestNotifier extends Notifier<IngestState> {
  late IngestRepository _repo;

  @override
  IngestState build() {
    _repo = IngestRepository(ref.read(apiClientProvider));
    return const IngestState();
  }

  Future<void> process(File file, String fileName) async {
    state = const IngestState(phase: IngestPhase.uploading);
    try {
      final uploadUrl = await _repo.getUploadUrl(fileName, 'application/pdf');
      await _repo.uploadToStorage(uploadUrl.signedUrl, file, 'application/pdf');

      state = state.copyWith(phase: IngestPhase.processing);

      final result = await _repo.ingestPolicy(
        storagePath: uploadUrl.filePath,
        fileName: fileName,
      );

      state = state.copyWith(
        phase: IngestPhase.chatting,
        sessionId: result.sessionId,
        documentMetadataId: result.documentMetadataId,
        extraction: result.extraction,
        messages: [IngestMessage(role: 'ai', text: result.message)],
      );
    } catch (e) {
      state = state.copyWith(
        phase: IngestPhase.error,
        error: e is ApiException ? e.message : e.toString(),
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
      final aiText = result.text;
      final isSuccess = _detectSuccess(aiText);
      state = state.copyWith(
        messages: [...state.messages, IngestMessage(role: 'ai', text: aiText)],
        isSending: false,
        phase: isSuccess ? IngestPhase.success : IngestPhase.chatting,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  Future<void> reset() async {
    final sid = state.sessionId;
    if (sid != null) {
      try { await _repo.cancelSession(sid); } catch (_) {}
    }
    state = const IngestState();
  }

  // Detecta si la IA confirmó la creación de la póliza
  bool _detectSuccess(String text) {
    final lower = text.toLowerCase();
    return lower.contains('póliza creada') ||
        lower.contains('poliza creada') ||
        lower.contains('guardada exitosamente') ||
        lower.contains('registrada correctamente') ||
        lower.contains('policy created') ||
        lower.contains('successfully created');
  }
}

final ingestProvider = NotifierProvider<IngestNotifier, IngestState>(IngestNotifier.new);
