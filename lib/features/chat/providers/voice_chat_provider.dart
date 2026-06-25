import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
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
  // Set when the session is terminated for a non-recoverable reason (e.g. plan
  // quota exhausted). Blocks the auto-reconnect in _onSocketClosed while still
  // allowing the error message to be shown (unlike _disposed, which suppresses it).
  bool _terminated = false;

  // The session ID of the first Gemini connection in this voice call.
  // Sent as 'sessionId' header on reconnects so the backend reuses the same
  // ai_session row instead of creating a new one.
  String? _rootSessionId;

  // Full-duplex: the mic streams continuously and is NEVER gated on state. The OS
  // voice-processing unit (AEC) keeps the model's voice out of the mic signal, so
  // it's safe to keep sending while the model speaks — that's exactly what lets
  // Gemini's server VAD detect a barge-in and fire `interrupted`. `modelSpeaking`
  // is therefore a purely visual state, never a gate on the microphone.
  int _audioChunksReceived = 0; // for logging

  // Echo guard. The .voiceChat audio session mode does NOT fully cancel the
  // speaker, so the model's own voice leaks into the mic and trips Gemini's
  // server VAD, making the model interrupt itself mid-answer. While the model is
  // speaking — and for a short hangover after the last played chunk — we stop
  // FORWARDING mic audio to Gemini. The mic keeps capturing; we just don't send
  // the echo. Voice barge-in is unavailable in this window; the user interrupts
  // by tapping the screen, which calls interrupt() and re-opens the mic send.
  DateTime? _lastPlaybackAt;
  static const _playbackHangover = Duration(milliseconds: 700);

  // True from the instant the user taps to interrupt until the model turn
  // actually ends (turnComplete / server `interrupted`). While set, any model
  // audio/text that Gemini keeps streaming is DISCARDED — not played, not shown,
  // and it does NOT re-arm modelSpeaking or the echo guard. Without this, the
  // trailing audio re-closes the echo guard and the user's barge-in never reaches
  // Gemini, so it keeps talking for several seconds before recognizing speech.
  bool _discardingModelTurn = false;

  bool get _micSendBlockedByPlayback {
    if (_discardingModelTurn) return false; // interrupting → keep mic open for barge-in
    if (state.status == VoiceChatStatus.modelSpeaking) return true;
    final last = _lastPlaybackAt;
    return last != null &&
        DateTime.now().difference(last) < _playbackHangover;
  }

  // Silence watchdog: if the mic has been sending audio for > _stuckThreshold
  // without any Gemini response (no transcript, no audio, no turn_complete),
  // the Gemini Live session has likely become unresponsive. Reconnect.
  static const _stuckThreshold = Duration(seconds: 12);
  DateTime? _lastGeminiActivity;
  Timer? _watchdogTimer;
  String? _timezone; // stored so the watchdog can reconnect
  
  // Token usage trackers
  int _promptTokens = 0;
  int _completionTokens = 0;
  int _totalTokens = 0;

  @override
  VoiceChatState build() {
    ref.onDispose(_cleanup);
    return const VoiceChatState();
  }

  // ── Conexión ───────────────────────────────────────────────────────────────

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final response = await http.post(
      Uri.parse('${Env.apiBaseUrl}$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        if (_timezone != null) 'x-timezone': _timezone!,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('HTTP error ${response.statusCode}: ${response.body}');
    }
  }

  Future<dynamic> _executeToolInSupabase(String name, Map<String, dynamic> args) async {
    try {
      final res = await _post('/ai/voice/execute-tool', {
        'sessionId': state.sessionId,
        'timezone': _timezone,
        'toolName': name,
        'args': args,
      });
      return res; // returns whatever the function returns
    } catch (e) {
      debugPrint('[VoiceChat] executeTool error: $e');
      return {'error': e.toString()};
    }
  }

  Future<void> _saveRoundInSupabase(String userText, String modelText) async {
    try {
      await _post('/ai/voice/save-round', {
        'sessionId': state.sessionId,
        'userText': userText,
        'modelText': modelText,
        'promptTokens': _promptTokens,
        'completionTokens': _completionTokens,
        'totalTokens': _totalTokens,
      });
      debugPrint('[VoiceChat] Round saved in DB');
    } catch (e) {
      debugPrint('[VoiceChat] saveRound error: $e');
    }
  }

  Future<void> connect(String timezone) async {
    _timezone = timezone;
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      _setError('Sin sesión de usuario.');
      return;
    }

    try {
      // 1. Init session in Supabase to get prompt instructions and tool schemas
      debugPrint('[VoiceChat] Initializing session in Supabase...');
      final initData = await _post('/ai/voice/init', {
        'timezone': timezone,
        'sessionId': _rootSessionId,
      }) as Map<String, dynamic>;

      final sessionId = initData['sessionId'] as String;
      final systemInstruction = initData['systemInstruction'] as String;
      final tools = initData['tools'] as List<dynamic>? ?? [];

      _rootSessionId ??= sessionId;
      state = state.copyWith(
        status: VoiceChatStatus.connecting,
        sessionId: _rootSessionId,
      );

      // 2. Mint a short-lived Gemini token — fetched right before opening the
      // socket since it's only valid to START a session for ~60s. The raw
      // GEMINI_API_KEY never reaches the client, so it can't be extracted by
      // decompiling the app. systemInstruction/tools travel with it because the
      // backend bakes them into the token's liveConnectConstraints — once that's
      // set, Gemini locks the WHOLE session config and ignores whatever this
      // client sends in its own `setup` message below.
      final tokenData = await _post('/ai/voice/token', {
        'systemInstruction': systemInstruction,
        'tools': tools,
      }) as Map<String, dynamic>;
      final ephemeralToken = tokenData['token'] as String;

      // 3. Connect directly to Gemini Live API WebSocket. Ephemeral tokens only
      // work on the v1alpha endpoint, passed as the `access_token` query param —
      // and ONLY against the BidiGenerateContentConstrained method (not the plain
      // BidiGenerateContent one, which only accepts a real `key=` API key and
      // rejects `access_token` with close code 1008 "unregistered callers").
      final geminiWsUrl = 'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained?access_token=$ephemeralToken';
      debugPrint('[VoiceChat] Connecting directly to Gemini Live API');

      _socket = await WebSocket.connect(geminiWsUrl);

      _wsSub = _socket!.listen(
        _onMessage,
        onDone: _onSocketClosed,
        onError: (Object e) => _setError(e.toString()),
        cancelOnError: false,
      );

      debugPrint('[VoiceChat] WebSocket connected directly to Gemini');

      // 3. Send setup message to Gemini Live API
      final setupMessage = {
        'setup': {
          'model': 'models/${Env.geminiLiveModel}',
          'generation_config': {
            'response_modalities': ['AUDIO'],
          },
          'realtime_input_config': {
            'automatic_activity_detection': {
              // HIGH start sensitivity = reacts to quieter/shorter speech onsets, so a
              // barge-in is detected sooner. This is the only real interrupt mechanism
              // under automatic VAD — the client can't tell Gemini to stop generating;
              // tapping the screen only mutes local playback (see interrupt() above).
              'start_of_speech_sensitivity': 'START_SENSITIVITY_HIGH',
              'end_of_speech_sensitivity': 'END_SENSITIVITY_LOW',
              'prefix_padding_ms': 200,
              'silence_duration_ms': 500,
            },
          },
          'input_audio_transcription': {},
          'output_audio_transcription': {},
          'system_instruction': {
            'parts': [
              {'text': systemInstruction}
            ],
          },
          'tools': tools,
        }
      };

      _socket!.add(jsonEncode(setupMessage));
      debugPrint('[VoiceChat] Setup message sent to Gemini');

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
    await _cleanup();
    if (!_disposed) state = state.copyWith(status: VoiceChatStatus.closed);
  }

  // Commits the in-flight turn (the user's question AND whatever the model has
  // said so far) into `turns`, in the correct order (user first, then model),
  // and clears the live buffers. Called on a turn boundary — turnComplete, a tap
  // interrupt, or a server `interrupted`. Committing the user text here too is
  // what prevents the interrupted answer from landing BEFORE the question.
  void _commitCurrentTurn() {
    final user = state.liveUserText;
    final model = state.liveModelText;
    if (user.isEmpty && model.isEmpty) return;
    final newTurns = [...state.turns];
    if (user.isNotEmpty) newTurns.add(VoiceChatTurn(isUser: true, text: user));
    if (model.isNotEmpty) newTurns.add(VoiceChatTurn(isUser: false, text: model));
    state = state.copyWith(turns: newTurns, liveUserText: '', liveModelText: '');
  }

  Future<void> interrupt() async {
    if (state.status != VoiceChatStatus.modelSpeaking) return;
    debugPrint('[VoiceChat] Interrupt — stopping playback');

    // Discard any model audio/text that Gemini keeps streaming after this point,
    // and keep the mic open so the user's barge-in actually reaches Gemini.
    _discardingModelTurn = true;

    // Stop speaker output; AEC reference drops → no more echo to cancel
    try {
      await _audioControl.invokeMethod<void>('stopPlayback');
    } catch (e) {
      debugPrint('[VoiceChat] stopPlayback error: $e');
    }

    _commitCurrentTurn(); // keep the question + what the model already said, in order
    state = state.copyWith(status: VoiceChatStatus.listening);
  }

  // ── Mensajes entrantes de Gemini Live API ─────────────────────────────────

  Future<void> _onMessage(dynamic raw) async {
    if (_disposed) return;
    Map<String, dynamic> msg;
    try {
      String text;
      if (raw is String) {
        text = raw;
      } else if (raw is List<int>) {
        text = utf8.decode(raw);
      } else {
        debugPrint('[VoiceChat] Unknown raw payload type: ${raw.runtimeType}');
        return;
      }
      msg = jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[VoiceChat] Parse error: $e');
      return;
    }

    // Handle setupComplete
    final setupComplete = msg['setupComplete'] ?? msg['setup_complete'];
    if (setupComplete != null) {
      debugPrint('[VoiceChat] ▶ Gemini ready — entering LISTENING mode, starting mic');
      state = state.copyWith(status: VoiceChatStatus.listening);
      _touchGeminiActivity();
      _startMicStream();
      return;
    }

    // Handle usageMetadata
    final usageMetadata = msg['usageMetadata'] ?? msg['usage_metadata'];
    if (usageMetadata is Map) {
      _promptTokens = (usageMetadata['promptTokenCount'] ?? usageMetadata['prompt_token_count'] ?? 0) as int;
      _completionTokens = (usageMetadata['candidatesTokenCount'] ?? usageMetadata['candidates_token_count'] ?? 0) as int;
      _totalTokens = (usageMetadata['totalTokenCount'] ?? usageMetadata['total_token_count'] ?? 0) as int;
      debugPrint('[VoiceChat] Usage tokens updated: prompt=$_promptTokens completion=$_completionTokens total=$_totalTokens');
    }

    // Handle serverContent
    final serverContent = msg['serverContent'] ?? msg['server_content'];
    if (serverContent is Map) {
      _touchGeminiActivity();

      // Handle interrupted (barge-in). The mic never stopped, so Gemini already
      // heard the user — just flush the model audio still queued on the speaker.
      if (serverContent['interrupted'] == true) {
        final chunksBeforeInterrupt = _audioChunksReceived;
        _audioChunksReceived = 0;
        debugPrint('[VoiceChat] ⚡ INTERRUPTED after $chunksBeforeInterrupt chunks — flushing playback');
        try {
          await _audioControl.invokeMethod<void>('stopPlayback');
        } catch (_) {}
        // Pure voice barge-in (no prior tap): preserve the partial in order.
        // After a tap the turn was already committed, so don't re-commit — that
        // would fragment the new question the user is now speaking.
        if (!_discardingModelTurn) _commitCurrentTurn();
        _discardingModelTurn = false;
        state = state.copyWith(status: VoiceChatStatus.listening);
        debugPrint('[VoiceChat] 🎤 USER barge-in — model audio flushed');
      }

      // Handle modelTurn (audio chunks). Skipped entirely while discarding an
      // interrupted turn — playing/queuing this audio would re-arm modelSpeaking
      // and the echo guard, blocking the user's barge-in.
      final modelTurn = serverContent['modelTurn'] ?? serverContent['model_turn'];
      if (modelTurn is Map && modelTurn['parts'] is List && !_discardingModelTurn) {
        final parts = modelTurn['parts'] as List;
        for (final part in parts) {
          if (part is Map) {
            final inlineData = part['inlineData'] ?? part['inline_data'];
            if (inlineData is Map && inlineData['data'] is String) {
              final base64Audio = inlineData['data'] as String;
              if (base64Audio.isNotEmpty) {
                _audioChunksReceived++;
                _lastPlaybackAt = DateTime.now(); // arm the echo guard hangover
                try {
                  await _audioControl.invokeMethod<void>('playPcm', {'data': base64Audio});
                } catch (e) {
                  debugPrint('[VoiceChat] playPcm error: $e');
                }
              }
            }
          }
        }
        // Visual state only — the mic keeps streaming (full-duplex).
        if (state.status != VoiceChatStatus.modelSpeaking) {
          debugPrint('[VoiceChat] 🔊 MODEL speaking (mic stays open)');
          state = state.copyWith(status: VoiceChatStatus.modelSpeaking);
        }
      }

      // Handle outputTranscription (model text). Also skipped while discarding —
      // the partial was already committed at interrupt; trailing text would
      // append a second, out-of-place bubble.
      final outputTrans = serverContent['outputTranscription'] ?? serverContent['output_transcription'];
      if (outputTrans is Map && outputTrans['text'] is String && !_discardingModelTurn) {
        var text = outputTrans['text'] as String;
        text = text.replaceAll(RegExp(r'<ctrl\d+>'), '');
        debugPrint('[VoiceChat] 🤖 Model: "$text"');
        state = state.copyWith(
          status: VoiceChatStatus.modelSpeaking,
          liveModelText: state.liveModelText + text,
        );
      }

      // Handle inputTranscription (user text)
      final inputTrans = serverContent['inputTranscription'] ?? serverContent['input_transcription'];
      if (inputTrans is Map && inputTrans['text'] is String) {
        var text = inputTrans['text'] as String;
        text = text.replaceAll(RegExp(r'<ctrl\d+>'), '');
        debugPrint('[VoiceChat] 🎤 User: "$text"');
        state = state.copyWith(liveUserText: state.liveUserText + text);
        _armWatchdog(); // user spoke → expect a model reply; reconnect if none in 12s
      }

      // Handle turnComplete
      if (serverContent['turnComplete'] == true || serverContent['turn_complete'] == true) {
        final chunksThisTurn = _audioChunksReceived;
        _audioChunksReceived = 0;
        _discardingModelTurn = false; // turn ended — resume normal flow
        debugPrint('[VoiceChat] ✅ TURN COMPLETE ($chunksThisTurn chunks played) — saving round');

        final userText = state.liveUserText;
        final modelText = state.liveModelText;

        _commitCurrentTurn(); // user first, then model — clears the live buffers

        // Save round to Supabase asynchronously so it doesn't block the UI
        _saveRoundInSupabase(userText, modelText);

        state = state.copyWith(
          status: VoiceChatStatus.listening,
          clearActiveSkill: true,
        );

        // Reset usage token trackers
        _promptTokens = 0;
        _completionTokens = 0;
        _totalTokens = 0;
      }
    }

    // Handle toolCall
    final toolCall = msg['toolCall'] ?? msg['tool_call'];
    if (toolCall is Map) {
      final functionCalls = toolCall['functionCalls'] ?? toolCall['function_calls'];
      if (functionCalls is List && functionCalls.isNotEmpty) {
        _touchGeminiActivity(); // Gemini is responding (calling a tool) — cancel watchdog
        debugPrint('[VoiceChat] Tool calls received: $functionCalls');
        
        final futures = functionCalls.map((call) async {
          if (call is Map) {
            final id = call['id'] as String;
            final name = call['name'] as String;
            final args = call['args'] as Map<String, dynamic>? ?? {};

            state = state.copyWith(activeSkill: name);
            final result = await _executeToolInSupabase(name, args);

            // Backend signals the plan limit was hit — stop here, show the
            // message and tear down. Don't forward a tool response to Gemini.
            if (result is Map && result['quotaExceeded'] == true) {
              await _handleQuotaExceeded(result['message'] as String?);
              return null;
            }

            return {
              'id': id,
              'name': name,
              'response': {'result': result},
            };
          }
          return null;
        }).toList();

        final results = (await Future.wait(futures)).whereType<Map<String, dynamic>>().toList();

        // Send tool responses back to Gemini
        final toolResponse = {
          'tool_response': {
            'function_responses': results,
          }
        };
        _socket?.add(jsonEncode(toolResponse));
        debugPrint('[VoiceChat] Sent tool responses to Gemini');
        
        state = state.copyWith(clearActiveSkill: true);
      }
    }
  }

  void _onSocketClosed() {
    debugPrint('[VoiceChat] Socket closed by server');
    if (_disposed || _terminated) return; // user-ended or quota-terminated — no reconnect

    // Gemini Live sessions have a duration/context limit and the server can close
    // mid-turn. Reconnect transparently so the user doesn't lose the session.
    debugPrint('[VoiceChat] ♻ Server closed socket — reconnecting transparently');
    _reconnect();
  }

  // ── Micrófono (via native EventChannel) ───────────────────────────────────

  bool _hasReceivedMicData = false;
  int _micChunksSent = 0;

  void _startMicStream() {
    _hasReceivedMicData = false;
    _micChunksSent = 0;
    _audioSub = _audioInput.receiveBroadcastStream().listen(
      (dynamic data) {
        if (_disposed) return;
        if (data is! Uint8List) return;
        if (!_hasReceivedMicData) {
          _hasReceivedMicData = true;
          debugPrint('[VoiceChat] 🎙 First mic chunk arrived (${data.length} bytes)');
        }
        // Echo guard: while the model is speaking (and a short hangover after),
        // don't forward mic audio — otherwise the speaker bleed trips Gemini's VAD
        // and the model interrupts itself. The mic still captures; we just hold the
        // send. Tapping the screen (interrupt()) re-opens the send immediately.
        if (_socket?.readyState == WebSocket.open && !_micSendBlockedByPlayback) {
          _micChunksSent++;
          if (_micChunksSent % 50 == 0) {
            debugPrint('[VoiceChat] 📤 Mic streaming ($_micChunksSent chunks)');
          }
          final pcmChunkMessage = {
            'realtime_input': {
              'media_chunks': [
                {
                  'mime_type': 'audio/pcm;rate=16000',
                  'data': base64Encode(data),
                }
              ]
            }
          };
          _socket!.add(jsonEncode(pcmChunkMessage));
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

  // Arms the watchdog timer. Called when the user starts speaking (Gemini emits an
  // input transcription). If no Gemini activity follows within _stuckThreshold, the
  // Live session is considered stuck and gets reconnected transparently. Any inbound
  // server content / tool call calls _touchGeminiActivity() which cancels it.
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
    _audioChunksReceived = 0;
    _discardingModelTurn = false;
    await _audioSub?.cancel();
    _audioSub = null;
    await _wsSub?.cancel();
    _wsSub = null;
    try { await _audioControl.invokeMethod<void>('stopAudio'); } catch (_) {}
    try { await _socket?.close(); } catch (_) {}
    _socket = null;
  }

  // Plan quota exhausted (signaled by the backend on an execute-tool call).
  // Tears down audio + socket without triggering a reconnect, then surfaces the
  // limit message as an error state. The screen stays open (it only auto-pops on
  // `closed`, not `error`) so the user can read it and close manually.
  Future<void> _handleQuotaExceeded(String? message) async {
    if (_terminated || _disposed) return;
    debugPrint('[VoiceChat] 🚫 Plan limit reached — terminating voice session');
    _terminated = true;
    await _partialCleanup();
    _setError(message ?? 'Has alcanzado el límite de tu plan.');
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
