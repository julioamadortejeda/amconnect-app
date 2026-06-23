import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';

// ── Tipos públicos ────────────────────────────────────────────────────────────

enum VoiceChatStatus {
  connecting,
  ready,
  listening,
  modelSpeaking,
  error,
  closed,
}

@immutable
class VoiceChatTurn {
  final bool isUser;
  final String text;
  const VoiceChatTurn({required this.isUser, required this.text});
}

@immutable
class VoiceChatState {
  final VoiceChatStatus status;
  final String? sessionId;
  final List<VoiceChatTurn> turns;
  final String liveUserText;
  final String liveModelText;
  final String? activeSkill;
  final String? error;

  const VoiceChatState({
    this.status = VoiceChatStatus.connecting,
    this.sessionId,
    this.turns = const [],
    this.liveUserText = '',
    this.liveModelText = '',
    this.activeSkill,
    this.error,
  });

  VoiceChatState copyWith({
    VoiceChatStatus? status,
    String? sessionId,
    List<VoiceChatTurn>? turns,
    String? liveUserText,
    String? liveModelText,
    String? activeSkill,
    bool clearActiveSkill = false,
    String? error,
  }) {
    return VoiceChatState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      turns: turns ?? this.turns,
      liveUserText: liveUserText ?? this.liveUserText,
      liveModelText: liveModelText ?? this.liveModelText,
      activeSkill: clearActiveSkill ? null : (activeSkill ?? this.activeSkill),
      error: error ?? this.error,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final voiceChatProvider =
    NotifierProvider.autoDispose<VoiceChatNotifier, VoiceChatState>(
  VoiceChatNotifier.new,
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class VoiceChatNotifier extends Notifier<VoiceChatState> {
  static const _audioControl = MethodChannel('com.amconnect/audio');
  static const _audioInput   = EventChannel('com.amconnect/audio_input');

  WebSocket? _socket;
  StreamSubscription<dynamic>? _wsSub;
  StreamSubscription<dynamic>? _audioSub;
  bool _disposed = false;

  @override
  VoiceChatState build() {
    ref.onDispose(_cleanup);
    return const VoiceChatState();
  }

  // ── Conexión ───────────────────────────────────────────────────────────────

  Future<void> connect(String timezone) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      _setError('Sin sesión de usuario.');
      return;
    }

    final base = Env.apiBaseUrl;
    final wsBase = base
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final wsUrl = '$wsBase/ai/voice';

    debugPrint('[VoiceChat] Connecting to $wsUrl');

    try {
      _socket = await WebSocket.connect(wsUrl, headers: {
        'Authorization': 'Bearer $token',
        'x-timezone': timezone,
      });

      _wsSub = _socket!.listen(
        _onMessage,
        onDone: _onSocketClosed,
        onError: (Object e) => _setError(e.toString()),
        cancelOnError: false,
      );

      debugPrint('[VoiceChat] WebSocket connected');

      // Start the native audio engine (capture + playback in one AVAudioEngine)
      await _audioControl.invokeMethod<void>('startAudio');
    } catch (e) {
      debugPrint('[VoiceChat] Connection failed: $e');
      if (!_disposed) _setError('No se pudo conectar: $e');
    }
  }

  Future<void> endSession() async {
    debugPrint('[VoiceChat] Ending session');
    if (_socket?.readyState == WebSocket.open) {
      _socket!.add(jsonEncode({'type': 'end'}));
    }
    await _cleanup();
    if (!_disposed) state = state.copyWith(status: VoiceChatStatus.closed);
  }

  Future<void> interrupt() async {
    if (state.status != VoiceChatStatus.modelSpeaking) return;
    debugPrint('[VoiceChat] Interrupt — stopping playback');

    // Stop speaker output; AEC reference drops → no more echo to cancel
    try {
      await _audioControl.invokeMethod<void>('stopPlayback');
    } catch (e) {
      debugPrint('[VoiceChat] stopPlayback error: $e');
    }

    state = state.copyWith(
      status: VoiceChatStatus.listening,
      liveModelText: '',
    );

    // Send 50 ms of silence to trigger Gemini server-side VAD interrupt
    if (_socket?.readyState == WebSocket.open) {
      final dummySilence = Uint8List(1600);
      _socket!.add(jsonEncode({
        'type': 'audio',
        'data': base64Encode(dummySilence),
      }));
    }
  }

  // ── Mensajes entrantes del backend ────────────────────────────────────────

  Future<void> _onMessage(dynamic raw) async {
    if (_disposed) return;
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[VoiceChat] Parse error: $e');
      return;
    }

    final type = msg['type'] as String?;
    debugPrint('[VoiceChat] << $type');

    switch (type) {
      case 'ready':
        state = state.copyWith(
          status: VoiceChatStatus.ready,
          sessionId: msg['session_id'] as String?,
        );

      case 'gemini_ready':
        debugPrint('[VoiceChat] Gemini ready — starting mic stream');
        state = state.copyWith(status: VoiceChatStatus.listening);
        _startMicStream();

      case 'audio':
        final base64Audio = msg['data'] as String? ?? '';
        if (base64Audio.isNotEmpty) {
          try {
            // Play PCM through the same native engine — AEC has the reference
            await _audioControl.invokeMethod<void>('playPcm', {'data': base64Audio});
          } catch (e) {
            debugPrint('[VoiceChat] playPcm error: $e');
          }
        }
        if (state.status != VoiceChatStatus.modelSpeaking) {
          state = state.copyWith(status: VoiceChatStatus.modelSpeaking);
        }

      case 'transcript_user':
        var text = msg['text'] as String? ?? '';
        text = text.replaceAll(RegExp(r'<ctrl\d+>'), '');
        state = state.copyWith(liveUserText: state.liveUserText + text);

      case 'transcript_model':
        var text = msg['text'] as String? ?? '';
        text = text.replaceAll(RegExp(r'<ctrl\d+>'), '');
        if (state.status != VoiceChatStatus.modelSpeaking) {
          state = state.copyWith(
            status: VoiceChatStatus.modelSpeaking,
            liveModelText: state.liveModelText + text,
          );
        } else {
          state = state.copyWith(liveModelText: state.liveModelText + text);
        }

      case 'interrupted':
        debugPrint('[VoiceChat] Barge-in — back to listening');
        try {
          await _audioControl.invokeMethod<void>('stopPlayback');
        } catch (_) {}
        state = state.copyWith(
          status: VoiceChatStatus.listening,
          liveModelText: '',
        );

      case 'turn_complete':
        final newTurns = [...state.turns];
        if (state.liveUserText.isNotEmpty) {
          newTurns.add(VoiceChatTurn(isUser: true, text: state.liveUserText));
        }
        if (state.liveModelText.isNotEmpty) {
          newTurns.add(VoiceChatTurn(isUser: false, text: state.liveModelText));
        }
        state = VoiceChatState(
          status: VoiceChatStatus.listening,
          sessionId: state.sessionId,
          turns: newTurns,
        );

      case 'skill_call':
        final name = msg['name'] as String?;
        debugPrint('[VoiceChat] Skill executing: $name');
        state = state.copyWith(activeSkill: name);

      case 'error':
        final message = msg['message'] as String? ?? 'Error desconocido';
        debugPrint('[VoiceChat] Error from backend: $message');
        _setError(message);

      case 'closed':
        debugPrint('[VoiceChat] Backend closed session');
        if (!_disposed) state = state.copyWith(status: VoiceChatStatus.closed);
    }
  }

  void _onSocketClosed() {
    debugPrint('[VoiceChat] Socket closed');
    if (!_disposed) state = state.copyWith(status: VoiceChatStatus.closed);
  }

  // ── Micrófono (via native EventChannel) ───────────────────────────────────

  void _startMicStream() {
    _audioSub = _audioInput.receiveBroadcastStream().listen(
      (dynamic data) {
        if (_disposed) return;
        if (data is! Uint8List) return;
        if (_socket?.readyState == WebSocket.open) {
          _socket!.add(jsonEncode({
            'type': 'audio',
            'data': base64Encode(data),
          }));
        }
      },
      onError: (Object e) {
        debugPrint('[VoiceChat] Audio input error: $e');
      },
    );
    debugPrint('[VoiceChat] Native mic stream started');
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────

  Future<void> _cleanup() async {
    _disposed = true;
    await _audioSub?.cancel();
    _audioSub = null;
    await _wsSub?.cancel();
    _wsSub = null;
    try {
      await _audioControl.invokeMethod<void>('stopAudio');
    } catch (_) {}
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    debugPrint('[VoiceChat] Cleanup done');
  }

  void _setError(String message) {
    if (!_disposed) {
      state = state.copyWith(status: VoiceChatStatus.error, error: message);
    }
  }
}
