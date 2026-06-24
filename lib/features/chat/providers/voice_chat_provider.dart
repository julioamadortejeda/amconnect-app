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

  // The session ID of the first Gemini connection in this voice call.
  // Sent as 'sessionId' header on reconnects so the backend reuses the same
  // ai_session row instead of creating a new one.
  String? _rootSessionId;

  // Half-duplex state:
  // _discardAudio: true after `interrupted` — ignores in-flight audio chunks from
  //   the old turn so they can't flip state back to modelSpeaking and mute the mic.
  //   Reset to false on `turn_complete` so the next model response is played normally.
  // _micCooldown: true after `turn_complete` while waiting for buffered audio to
  //   finish playing on the speaker. Prevents the mic from picking up that tail audio
  //   (echo) and sending it to Gemini as if the user was speaking.
  bool _discardAudio = false;
  bool _micCooldown  = false;

  int _audioChunksReceived = 0; // for logging

  // Silence watchdog: if the mic has been sending audio for > _stuckThreshold
  // without any Gemini response (no transcript, no audio, no turn_complete),
  // the Gemini Live session has likely become unresponsive. Reconnect.
  static const _stuckThreshold = Duration(seconds: 12);
  DateTime? _lastGeminiActivity;
  Timer? _watchdogTimer;
  String? _timezone; // stored so the watchdog can reconnect

  @override
  VoiceChatState build() {
    ref.onDispose(_cleanup);
    return const VoiceChatState();
  }

  // ── Conexión ───────────────────────────────────────────────────────────────

  Future<void> connect(String timezone) async {
    _timezone = timezone;
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
        if (_rootSessionId != null) 'sessionId': _rootSessionId!,
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
      await _cleanup();
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
    if (type != 'audio') {
      debugPrint('[VoiceChat] << $type');
    }

    switch (type) {
      case 'ready':
        final sid = msg['session_id'] as String?;
        _rootSessionId ??= sid; // pin to first session; stays across reconnects
        state = state.copyWith(
          status: VoiceChatStatus.ready,
          sessionId: _rootSessionId,
        );

      case 'gemini_ready':
        debugPrint('[VoiceChat] ▶ Gemini ready — entering LISTENING mode, starting mic');
        state = state.copyWith(status: VoiceChatStatus.listening);
        _touchGeminiActivity();
        _startMicStream();

      case 'audio':
        // Discard in-flight audio chunks from an interrupted turn.
        // Without this guard, late chunks arrive after `interrupted` and flip the
        // state back to modelSpeaking — silencing the mic indefinitely.
        if (_discardAudio) {
          debugPrint('[VoiceChat] ⊘ Discarding in-flight audio chunk (post-interrupt)');
          break;
        }
        _touchGeminiActivity();
        _audioChunksReceived++;
        final base64Audio = msg['data'] as String? ?? '';
        if (base64Audio.isNotEmpty) {
          try {
            await _audioControl.invokeMethod<void>('playPcm', {'data': base64Audio});
          } catch (e) {
            debugPrint('[VoiceChat] playPcm error: $e');
          }
        }
        if (state.status != VoiceChatStatus.modelSpeaking) {
          debugPrint('[VoiceChat] 🔊 MODEL speaking — mic MUTED (half-duplex)');
          state = state.copyWith(status: VoiceChatStatus.modelSpeaking);
        }

      case 'transcript_user':
        var text = msg['text'] as String? ?? '';
        text = text.replaceAll(RegExp(r'<ctrl\d+>'), '');
        debugPrint('[VoiceChat] 🎤 User: "$text"');
        _touchGeminiActivity();
        state = state.copyWith(liveUserText: state.liveUserText + text);

      case 'transcript_model':
        var text = msg['text'] as String? ?? '';
        text = text.replaceAll(RegExp(r'<ctrl\d+>'), '');
        debugPrint('[VoiceChat] 🤖 Model: "$text"');
        if (state.status != VoiceChatStatus.modelSpeaking) {
          state = state.copyWith(
            status: VoiceChatStatus.modelSpeaking,
            liveModelText: state.liveModelText + text,
          );
        } else {
          state = state.copyWith(liveModelText: state.liveModelText + text);
        }

      case 'interrupted':
        // Flag to discard in-flight audio from the interrupted turn.
        // Cleared on the next turn_complete so the model's next response plays.
        _discardAudio = true;
        final chunksBeforeInterrupt = _audioChunksReceived;
        _audioChunksReceived = 0;
        debugPrint('[VoiceChat] ⚡ INTERRUPTED after $chunksBeforeInterrupt chunks — stopping playback');
        try {
          await _audioControl.invokeMethod<void>('stopPlayback');
        } catch (_) {}
        state = state.copyWith(
          status: VoiceChatStatus.listening,
          liveModelText: '',
        );
        debugPrint('[VoiceChat] 🎤 USER turn (barge-in) — mic ACTIVE');

      case 'turn_complete':
        // Re-arm for the next model response.
        _discardAudio = false;
        final chunksThisTurn = _audioChunksReceived;
        _audioChunksReceived = 0;
        debugPrint('[VoiceChat] ✅ TURN COMPLETE ($chunksThisTurn chunks played) — entering mic cooldown');

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

        // Wait for the native player to finish draining its buffer before enabling
        // the mic. Without this wait the mic would pick up the tail of the model's
        // audio (speaker → mic echo) and send it to Gemini as user speech.
        _micCooldown = true;
        _waitForPlaybackDone();

      case 'skill_call':
        final name = msg['name'] as String?;
        debugPrint('[VoiceChat] 🛠 Skill executing: $name');
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
    debugPrint('[VoiceChat] Socket closed by server');
    if (_disposed) return; // user-initiated via endSession() — screen already closing

    // Gemini Live sessions have a duration/context limit and the server can close
    // mid-turn. Reconnect transparently so the user doesn't lose the session.
    debugPrint('[VoiceChat] ♻ Server closed socket — reconnecting transparently');
    _reconnect();
  }

  // ── Micrófono (via native EventChannel) ───────────────────────────────────

  bool _hasReceivedMicData = false;
  int _micChunksSent = 0;
  int _micMutedLogCounter = 0;

  void _startMicStream() {
    _hasReceivedMicData = false;
    _micChunksSent = 0;
    _micMutedLogCounter = 0;
    _audioSub = _audioInput.receiveBroadcastStream().listen(
      (dynamic data) {
        if (_disposed) return;
        if (data is! Uint8List) return;
        if (!_hasReceivedMicData) {
          _hasReceivedMicData = true;
          debugPrint('[VoiceChat] 🎙 First mic chunk arrived (${data.length} bytes)');
        }
        // Half-duplex: block mic while model is speaking OR during post-turn cooldown.
        // modelSpeaking → prevents echo while Gemini talks.
        // _micCooldown → prevents echo from the tail of buffered audio after turn_complete.
        if (_micCooldown || state.status == VoiceChatStatus.modelSpeaking) {
          _micMutedLogCounter++;
          if (_micMutedLogCounter % 40 == 1) {
            final reason = _micCooldown ? 'cooldown' : 'modelSpeaking';
            debugPrint('[VoiceChat] 🔇 Mic MUTED ($reason) — ${_micMutedLogCounter} chunks dropped');
          }
          return;
        }
        _micMutedLogCounter = 0;
        if (_socket?.readyState == WebSocket.open) {
          _micChunksSent++;
          if (_micChunksSent == 1) {
            debugPrint('[VoiceChat] 📤 Mic sending to Gemini (chunk #1 this turn)');
            _armWatchdog(); // start countdown — if Gemini doesn't respond in 12s, reconnect
          } else if (_micChunksSent % 20 == 0) {
            debugPrint('[VoiceChat] 📤 Mic: $_micChunksSent chunks sent this turn');
          }
          _socket!.add(jsonEncode({
            'type': 'audio',
            'data': base64Encode(data),
          }));
        }
      },
      onError: (Object e) {
        debugPrint('[VoiceChat] Mic input error: $e');
      },
    );
    debugPrint('[VoiceChat] Native mic stream started');
  }

  // ── Watchdog de sesión Gemini ─────────────────────────────────────────────

  void _touchGeminiActivity() {
    _lastGeminiActivity = DateTime.now();
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  // Arms the watchdog timer. Called each time the mic sends its first chunk of
  // a turn. If Gemini doesn't respond within _stuckThreshold, the session is
  // considered stuck and gets reconnected transparently.
  void _armWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(_stuckThreshold, () {
      if (_disposed) return;
      final since = DateTime.now().difference(_lastGeminiActivity ?? DateTime.now());
      debugPrint('[VoiceChat] ⚠ Watchdog: no Gemini activity for ${since.inSeconds}s — reconnecting');
      _reconnect();
    });
  }

  Future<void> _reconnect() async {
    debugPrint('[VoiceChat] ♻ Reconnecting session...');
    final tz = _timezone ?? '';
    final turns = state.turns; // preserve transcript
    final sessionId = state.sessionId;

    await _partialCleanup();
    if (_disposed) return;

    state = VoiceChatState(
      status: VoiceChatStatus.connecting,
      sessionId: sessionId,
      turns: turns,
    );
    await connect(tz);
  }

  // Closes the socket and audio but does NOT set _disposed (allows reconnect).
  Future<void> _partialCleanup() async {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _discardAudio = false;
    _micCooldown  = false;
    _audioChunksReceived = 0;
    await _audioSub?.cancel();
    _audioSub = null;
    await _wsSub?.cancel();
    _wsSub = null;
    try { await _audioControl.invokeMethod<void>('stopAudio'); } catch (_) {}
    try { await _socket?.close(); } catch (_) {}
    _socket = null;
  }

  // Polls native until the AVAudioPlayerNode has drained its scheduled buffers,
  // then clears the cooldown flag so the mic can resume.
  Future<void> _waitForPlaybackDone() async {
    debugPrint('[VoiceChat] ⏳ Waiting for playback to drain…');
    int polls = 0;
    while (!_disposed) {
      await Future.delayed(const Duration(milliseconds: 50));
      polls++;
      try {
        final done = await _audioControl.invokeMethod<bool>('isPlaybackDone') ?? true;
        if (done) {
          // Extra 100 ms for room echo to dissipate before mic resumes.
          await Future.delayed(const Duration(milliseconds: 100));
          if (!_disposed) {
            _micCooldown = false;
            _micChunksSent = 0;
            debugPrint('[VoiceChat] 🎤 USER turn — mic ACTIVE (drained in ${polls * 50}ms)');
          }
          return;
        }
      } catch (_) {
        break; // native channel gone (session ended) — bail out
      }
    }
    // Fallback: release cooldown even if polling fails.
    if (!_disposed) {
      _micCooldown = false;
      debugPrint('[VoiceChat] 🎤 USER turn — mic ACTIVE (fallback after ${polls * 50}ms)');
    }
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────

  Future<void> _cleanup() async {
    _disposed = true;
    _rootSessionId = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
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
