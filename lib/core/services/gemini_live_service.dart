import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Sealed hierarchy of typed events emitted by GeminiLiveService
abstract class GeminiLiveEvent {
  const GeminiLiveEvent();
}

class GeminiSetupCompleteEvent extends GeminiLiveEvent {
  const GeminiSetupCompleteEvent();
}

class GeminiAudioChunkEvent extends GeminiLiveEvent {
  final String base64PcmAudio;
  const GeminiAudioChunkEvent(this.base64PcmAudio);
}

class GeminiTranscriptionEvent extends GeminiLiveEvent {
  final String? userText;
  final String? modelText;
  const GeminiTranscriptionEvent({this.userText, this.modelText});
}

class GeminiUsageMetadataEvent extends GeminiLiveEvent {
  final Map<String, dynamic> usageMetadata;
  const GeminiUsageMetadataEvent(this.usageMetadata);
}

class GeminiToolCallEvent extends GeminiLiveEvent {
  final List<Map<String, dynamic>> functionCalls;
  const GeminiToolCallEvent(this.functionCalls);
}

class GeminiTurnCompleteEvent extends GeminiLiveEvent {
  final int chunksThisTurn;
  const GeminiTurnCompleteEvent(this.chunksThisTurn);
}

class GeminiInterruptedEvent extends GeminiLiveEvent {
  const GeminiInterruptedEvent();
}

class GeminiErrorEvent extends GeminiLiveEvent {
  final String message;
  const GeminiErrorEvent(this.message);
}

class GeminiLiveService {
  WebSocket? _socket;
  StreamSubscription? _socketSubscription;

  final _eventsController = StreamController<GeminiLiveEvent>.broadcast();
  Stream<GeminiLiveEvent> get events => _eventsController.stream;

  bool get isConnected => _socket != null && _socket!.readyState == WebSocket.open;

  Future<void> connect({
    required String url,
    required String token,
    required String systemInstruction,
    required String dynamicContext,
    required List<dynamic> tools,
    Map<String, dynamic>? headersMap,
    String modelName = 'models/gemini-2.0-flash-exp',
    required String logTag,
  }) async {
    await close();

    // El backend de studio devuelve la URL ya con `?access_token=<token>`
    // (WS Constrained de v1alpha); el de vertex la devuelve limpia y el token
    // va aparte. Concatenar sin mirar duplicaba el parámetro en studio y
    // Gemini cerraba con 1007 "Missing or malformed auth token".
    final wsUri = Uri.parse(
        url.contains('access_token=') ? url : '$url?access_token=$token');
    final headers = <String, String>{};
    if (headersMap != null) {
      headersMap.forEach((k, v) {
        headers[k] = v.toString();
      });
    }

    try {
      _socket = await WebSocket.connect(wsUri.toString(), headers: headers.isEmpty ? null : headers);
      debugPrint('[$logTag] Direct WebSocket connected to Gemini!');

      _socketSubscription = _socket!.listen(
        (data) => _onServerMessage(data, logTag: logTag),
        onError: (err) {
          debugPrint('[$logTag] WebSocket error: $err');
          _eventsController.add(GeminiErrorEvent('Error de conexión en vivo: $err'));
        },
        onDone: () {
          debugPrint('[$logTag] WebSocket closed — code=${_socket?.closeCode} '
              'reason="${_socket?.closeReason}"');
        },
      );

      // Este voiceName solo aplica de verdad en Vertex: ahí el WS no usa
      // token efímero con constraints, así que el `setup` que manda el
      // cliente sí se respeta. En Studio (token efímero v1alpha) el backend
      // ya fija la voz al crear el token (liveConnectConstraints.config) y
      // este bloque se ignora en silencio — ver gemini.provider.ts.
      final setupMessage = {
        'setup': {
          'model': modelName,
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {'voiceName': 'Aoede'}
              }
            }
          },
          'realtimeInputConfig': {
            'automaticActivityDetection': {
              'startOfSpeechSensitivity': 'START_SENSITIVITY_HIGH',
              'endOfSpeechSensitivity': 'END_SENSITIVITY_LOW',
              'prefixPaddingMs': 200,
              'silenceDurationMs': 1800,
            },
          },
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction}
            ]
          },
          'tools': tools,
          'inputAudioTranscription': {},
          'outputAudioTranscription': {},
        }
      };

      _socket!.add(jsonEncode(setupMessage));
      debugPrint('[$logTag] Setup message sent. SystemInstruction length: ${systemInstruction.length}');

      if (dynamicContext.isNotEmpty) {
        final contextMessage = {
          'clientContent': {
            'turns': [
              {
                'role': 'user',
                'parts': [
                  {'text': dynamicContext}
                ]
              }
            ],
            'turnComplete': false
          }
        };
        _socket!.add(jsonEncode(contextMessage));
        debugPrint('[$logTag] Dynamic context sent to Gemini');
      }
    } catch (e) {
      debugPrint('[$logTag] Connection error: $e');
      _eventsController.add(GeminiErrorEvent(e.toString()));
      rethrow;
    }
  }

  void sendAudioChunk(Uint8List bytes) {
    if (!isConnected) return;
    final base64Audio = base64Encode(bytes);
    // Formato nuevo `realtimeInput.audio` — el viejo `mediaChunks` provoca que
    // Gemini 3.1 Live API desconecte el WebSocket (fix validado 2026-07).
    final message = {
      'realtimeInput': {
        'audio': {
          'mimeType': 'audio/pcm;rate=16000',
          'data': base64Audio,
        }
      }
    };
    _socket?.add(jsonEncode(message));
  }

  void sendToolResponses(List<Map<String, dynamic>> results) {
    if (!isConnected || results.isEmpty) return;
    final toolResponse = {
      'toolResponse': {
        'functionResponses': results,
      }
    };
    _socket?.add(jsonEncode(toolResponse));
  }

  int _audioChunksReceived = 0;

  void _onServerMessage(dynamic rawData, {required String logTag}) {
    // Gemini Live manda los mensajes como frames BINARIOS (JSON en bytes) —
    // el WebSocket de Vertex siempre, el de Studio según el caso. Descartar
    // lo que no sea String deja la sesión muda: nunca llega setupComplete.
    final String text;
    if (rawData is String) {
      text = rawData;
    } else if (rawData is List<int>) {
      text = utf8.decode(rawData, allowMalformed: true);
    } else {
      debugPrint('[$logTag] Unknown WS frame type: ${rawData.runtimeType}');
      return;
    }

    try {
      final msg = jsonDecode(text) as Map<String, dynamic>;

      final setupComplete = msg['setupComplete'] ?? msg['setup_complete'];
      if (setupComplete != null) {
        debugPrint('[$logTag] Setup complete!');
        _audioChunksReceived = 0;
        _eventsController.add(const GeminiSetupCompleteEvent());
        return;
      }

      final usageMetadata = msg['usageMetadata'] ?? msg['usage_metadata'];
      if (usageMetadata is Map<String, dynamic>) {
        _eventsController.add(GeminiUsageMetadataEvent(usageMetadata));
      }

      final serverContent = msg['serverContent'] ?? msg['server_content'];
      if (serverContent is Map) {
        // Sin `return` temprano: un mismo mensaje puede traer `interrupted`
        // junto con transcripciones o `turnComplete` — hay que procesarlo todo.
        if (serverContent['interrupted'] == true) {
          _audioChunksReceived = 0;
          _eventsController.add(const GeminiInterruptedEvent());
        }

        final modelTurn = serverContent['modelTurn'] ?? serverContent['model_turn'];
        if (modelTurn is Map && modelTurn['parts'] is List) {
          final parts = modelTurn['parts'] as List;
          for (final part in parts) {
            if (part is Map) {
              final inlineData = part['inlineData'] ?? part['inline_data'];
              if (inlineData is Map && inlineData['data'] is String) {
                final base64Audio = inlineData['data'] as String;
                if (base64Audio.isNotEmpty) {
                  _audioChunksReceived++;
                  _eventsController.add(GeminiAudioChunkEvent(base64Audio));
                }
              }
            }
          }
        }

        final outputTrans = serverContent['outputTranscription'] ?? serverContent['output_transcription'];
        final inputTrans = serverContent['inputTranscription'] ?? serverContent['input_transcription'];
        String? modelText;
        String? userText;

        if (outputTrans is Map && outputTrans['text'] is String) {
          modelText = (outputTrans['text'] as String).replaceAll(RegExp(r'<ctrl\d+>'), '');
        }
        if (inputTrans is Map && inputTrans['text'] is String) {
          userText = (inputTrans['text'] as String).replaceAll(RegExp(r'<ctrl\d+>'), '');
        }

        if (userText != null || modelText != null) {
          _eventsController.add(GeminiTranscriptionEvent(userText: userText, modelText: modelText));
        }

        if (serverContent['turnComplete'] == true || serverContent['turn_complete'] == true) {
          final chunksThisTurn = _audioChunksReceived;
          _audioChunksReceived = 0;
          _eventsController.add(GeminiTurnCompleteEvent(chunksThisTurn));
        }
      }

      final toolCall = msg['toolCall'] ?? msg['tool_call'];
      if (toolCall is Map) {
        final functionCalls = toolCall['functionCalls'] ?? toolCall['function_calls'];
        if (functionCalls is List && functionCalls.isNotEmpty) {
          _eventsController.add(GeminiToolCallEvent(List<Map<String, dynamic>>.from(functionCalls)));
        }
      }
    } catch (e) {
      debugPrint('[$logTag] JSON parse error: $e');
    }
  }

  Future<void> close() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _socket?.close();
    _socket = null;
  }

  void dispose() {
    close();
    _eventsController.close();
  }
}
