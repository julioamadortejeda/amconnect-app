import 'dart:async';
import 'package:flutter/foundation.dart';

/// Ronda lista para persistir en `/ai/voice/save-round`. El tracker NO conoce
/// sessionId ni hace HTTP — solo congela números y textos; quien lo escucha
/// (GeminiVoiceEngine) es el que sabe a qué sesión pertenece y cómo enviarla.
@immutable
class VoiceRoundPayload {
  final String userText;
  final String modelText;
  final List<Map<String, dynamic>> toolCalls;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final int textPromptTokens;
  final int audioPromptTokens;
  final int textCompletionTokens;
  final int audioCompletionTokens;

  const VoiceRoundPayload({
    required this.userText,
    required this.modelText,
    required this.toolCalls,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.textPromptTokens,
    required this.audioPromptTokens,
    required this.textCompletionTokens,
    required this.audioCompletionTokens,
  });
}

/// Acumula el `usageMetadata` del WebSocket de Gemini Live y resuelve la
/// carrera de mensajes: el conteo final de tokens de audio puede llegar en un
/// paquete separado DESPUÉS de `turnComplete`, así que la ronda no se emite en
/// `turnComplete` sino cuando llega ese paquete final (camino rápido) o cuando
/// vence el timer de seguridad de 800ms (Gemini no mandó nada más).
class GeminiUsageTracker {
  GeminiUsageTracker({required this.onRoundReady, required this.logTag});

  /// Único punto de salida de rondas — se dispara exactamente una vez por turno.
  final void Function(VoiceRoundPayload payload) onRoundReady;
  final String logTag;

  // Contadores vivos del turno en vuelo (Gemini los reporta acumulados por
  // turno: cada usageMetadata REEMPLAZA al anterior, no se suma).
  int _promptTokens = 0;
  int _completionTokens = 0;
  int _totalTokens = 0;
  int _textPromptTokens = 0;
  int _audioPromptTokens = 0;
  int _textCompletionTokens = 0;
  int _audioCompletionTokens = 0;

  // Ronda congelada en turnComplete, esperando su usageMetadata final.
  bool _awaitingFinalUsage = false;
  Timer? _usageSafetyTimer;
  String _pendingUserText = '';
  String _pendingModelText = '';
  List<Map<String, dynamic>> _pendingToolCalls = const [];
  int _pendingPromptTokens = 0;
  int _pendingCompletionTokens = 0;
  int _pendingTotalTokens = 0;
  int _pendingTextPromptTokens = 0;
  int _pendingAudioPromptTokens = 0;
  int _pendingTextCompletionTokens = 0;
  int _pendingAudioCompletionTokens = 0;

  void resetSession() {
    _usageSafetyTimer?.cancel();
    _usageSafetyTimer = null;
    _awaitingFinalUsage = false;
    _resetLiveCounters();
    _resetPending();
  }

  /// Procesa el `usageMetadata` crudo (AI Studio o Vertex — los nombres de
  /// campo difieren y se aceptan ambos).
  void processUsageMetadata(Map<String, dynamic> usageMetadata) {
    _promptTokens = _readInt(usageMetadata, ['promptTokenCount', 'prompt_token_count']);
    // Studio Live reporta responseTokenCount; Vertex Live, candidatesTokenCount
    // (verificado 2026-07-09 contra ambos WebSockets).
    _completionTokens = _readInt(usageMetadata, [
      'responseTokenCount',
      'response_token_count',
      'candidatesTokenCount',
      'candidates_token_count',
    ]);
    _totalTokens = _readInt(usageMetadata, ['totalTokenCount', 'total_token_count']);
    final cachedTokens = _readInt(
        usageMetadata, ['cachedContentTokenCount', 'cached_content_token_count']);

    final promptByModality = _readModalities(usageMetadata, [
      'promptTokensDetails',
      'prompt_tokens_details',
      'inputTokensByModality',
      'input_tokens_by_modality',
    ]);
    _textPromptTokens = promptByModality.text;
    _audioPromptTokens = promptByModality.audio;

    final completionByModality = _readModalities(usageMetadata, [
      'responseTokensDetails',
      'response_tokens_details',
      'candidatesTokensDetails',
      'candidates_tokens_details',
      'outputTokensByModality',
      'output_tokens_by_modality',
    ]);
    _textCompletionTokens = completionByModality.text;
    _audioCompletionTokens = completionByModality.audio;

    debugPrint(
        '[$logTag] Usage tokens updated: prompt=$_promptTokens (text=$_textPromptTokens, audio=$_audioPromptTokens, cached=$cachedTokens) completion=$_completionTokens (text=$_textCompletionTokens, audio=$_audioCompletionTokens) total=$_totalTokens');

    // Este usageMetadata pertenece al turno que acaba de completarse y estaba
    // esperando su conteo final — refrescar la ronda pendiente y emitirla ya.
    if (_awaitingFinalUsage) {
      _pendingPromptTokens = _promptTokens;
      _pendingCompletionTokens = _completionTokens;
      _pendingTotalTokens = _totalTokens;
      _pendingTextPromptTokens = _textPromptTokens;
      _pendingAudioPromptTokens = _audioPromptTokens;
      _pendingTextCompletionTokens = _textCompletionTokens;
      _pendingAudioCompletionTokens = _audioCompletionTokens;
      flushPendingUsageRound();
    }
  }

  /// Congela el turno recién completado y arma el timer de seguridad. Si había
  /// una ronda anterior sin resolver, se emite primero con lo que tenía.
  void armPendingRoundSnapshot({
    required String userText,
    required String modelText,
    required List<Map<String, dynamic>> toolCalls,
  }) {
    flushPendingUsageRound();

    _pendingUserText = userText;
    _pendingModelText = modelText;
    _pendingToolCalls = toolCalls;
    _pendingPromptTokens = _promptTokens;
    _pendingCompletionTokens = _completionTokens;
    _pendingTotalTokens = _totalTokens;
    _pendingTextPromptTokens = _textPromptTokens;
    _pendingAudioPromptTokens = _audioPromptTokens;
    _pendingTextCompletionTokens = _textCompletionTokens;
    _pendingAudioCompletionTokens = _audioCompletionTokens;

    _resetLiveCounters();

    _awaitingFinalUsage = true;
    _usageSafetyTimer?.cancel();
    _usageSafetyTimer = Timer(const Duration(milliseconds: 800), () {
      debugPrint('[$logTag] Usage safety timer fired — emitting round with tokens on hand');
      flushPendingUsageRound();
    });
  }

  /// Emite la ronda pendiente vía [onRoundReady]. Idempotente: no-op si no hay
  /// nada pendiente, seguro de llamar desde varios call sites (usageMetadata
  /// tardío, timer, siguiente turnComplete, cierre de sesión).
  void flushPendingUsageRound() {
    if (!_awaitingFinalUsage) return;
    _awaitingFinalUsage = false;
    _usageSafetyTimer?.cancel();
    _usageSafetyTimer = null;

    onRoundReady(VoiceRoundPayload(
      userText: _pendingUserText,
      modelText: _pendingModelText,
      toolCalls: _pendingToolCalls,
      promptTokens: _pendingPromptTokens,
      completionTokens: _pendingCompletionTokens,
      totalTokens: _pendingTotalTokens,
      textPromptTokens: _pendingTextPromptTokens,
      audioPromptTokens: _pendingAudioPromptTokens,
      textCompletionTokens: _pendingTextCompletionTokens,
      audioCompletionTokens: _pendingAudioCompletionTokens,
    ));

    _resetPending();
  }

  void dispose() {
    _usageSafetyTimer?.cancel();
    _usageSafetyTimer = null;
  }

  void _resetLiveCounters() {
    _promptTokens = 0;
    _completionTokens = 0;
    _totalTokens = 0;
    _textPromptTokens = 0;
    _audioPromptTokens = 0;
    _textCompletionTokens = 0;
    _audioCompletionTokens = 0;
  }

  void _resetPending() {
    _pendingUserText = '';
    _pendingModelText = '';
    _pendingToolCalls = const [];
    _pendingPromptTokens = 0;
    _pendingCompletionTokens = 0;
    _pendingTotalTokens = 0;
    _pendingTextPromptTokens = 0;
    _pendingAudioPromptTokens = 0;
    _pendingTextCompletionTokens = 0;
    _pendingAudioCompletionTokens = 0;
  }

  static int _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
    }
    return 0;
  }

  static ({int text, int audio}) _readModalities(
      Map<String, dynamic> map, List<String> keys) {
    var text = 0;
    var audio = 0;
    dynamic details;
    for (final key in keys) {
      if (map[key] != null) {
        details = map[key];
        break;
      }
    }
    if (details is List) {
      for (final item in details) {
        if (item is Map) {
          final mod = (item['modality'] ?? '').toString().toUpperCase();
          final rawCount = item['tokenCount'] ?? item['token_count'] ?? item['tokens'] ?? 0;
          final count = rawCount is num ? rawCount.toInt() : 0;
          if (mod == 'TEXT') text += count;
          if (mod == 'AUDIO') audio += count;
        }
      }
    }
    return (text: text, audio: audio);
  }
}
