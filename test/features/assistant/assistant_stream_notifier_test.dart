import 'dart:async';

import 'package:amconnect/core/network/api_client.dart';
import 'package:amconnect/features/assistant/data/assistant_repository.dart';
import 'package:amconnect/features/assistant/providers/assistant_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositorio falso: el test controla el stream a mano.
class FakeAssistantRepository implements AssistantRepository {
  StreamController<AssistantStreamEvent>? controller;
  Object? connectError; // se emite como error del stream antes de todo evento
  int streamCalls = 0;
  int jsonCalls = 0;
  final cancelled = <String>[];
  AssistantChatResult jsonResult =
      (text: 'json', sessionId: 'sj', metadata: null, aiBackend: null);
  Object? jsonError;
  bool streamCancelled = false;

  @override
  Stream<AssistantStreamEvent> sendMessageStream(String message,
      {String? sessionId, covariant Object? context}) {
    streamCalls++;
    final c = controller = StreamController<AssistantStreamEvent>(
      onCancel: () => streamCancelled = true,
    );
    if (connectError != null) c.addError(connectError!);
    return c.stream;
  }

  @override
  Future<AssistantChatResult> sendMessage(String message,
      {String? sessionId, covariant Object? context}) async {
    jsonCalls++;
    if (jsonError != null) throw jsonError!;
    return jsonResult;
  }

  @override
  Future<void> cancelSession(String sessionId) async => cancelled.add(sessionId);
}

const _conn = ApiException(
    statusCode: 0, message: kConnectionFailedCode, errorCode: kConnectionFailedCode);

Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAssistantRepository repo;
  late ProviderContainer container;
  late AssistantNotifier notifier;

  AssistantState st() => container.read(assistantProvider);

  setUp(() {
    repo = FakeAssistantRepository();
    container = ProviderContainer(
      overrides: [assistantRepositoryProvider.overrideWithValue(repo)],
    );
    // Mantener vivo el provider durante el test.
    container.listen(assistantProvider, (_, __) {});
    notifier = container.read(assistantProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('flujo feliz: status → tool chip → delta → done', () async {
    final fut = notifier.sendText('hola');
    await _pump();
    expect(repo.streamCalls, 1);
    expect(st().isLoading, isTrue);
    expect(st().messages.single.role, 'user');

    final c = repo.controller!;
    c.add(const AssistantStreamStatus(phase: 'thinking', sessionId: 's1'));
    await _pump();
    expect(st().sessionId, 's1');

    c.add(const AssistantStreamTool(label: 'Buscando cliente', started: true));
    await _pump();
    expect(st().toolLabel, 'Buscando cliente');

    c.add(const AssistantStreamTool(label: 'Buscando cliente', started: false, ok: true));
    await _pump();
    expect(st().toolLabel, 'Buscando cliente'); // persiste tras finished

    c.add(const AssistantStreamDelta('Hola '));
    c.add(const AssistantStreamDelta('Ana'));
    await _pump();
    expect(st().toolLabel, isNull); // el texto limpia la etiqueta
    expect(st().streamingText, 'Hola Ana');
    expect(st().messages, hasLength(1)); // aún no se fija como mensaje

    c.add(const AssistantStreamDone((
      text: 'Hola Ana, listo.',
      sessionId: 's1',
      metadata: {'type': 'attachment_list'},
      aiBackend: 'vertex',
    )));
    await c.close();
    await fut;

    final s = st();
    expect(s.isLoading, isFalse);
    expect(s.streamingText, '');
    expect(s.toolLabel, isNull);
    expect(s.error, isNull);
    expect(s.messages, hasLength(2));
    // done es autoritativo: reemplaza el texto acumulado y trae la metadata.
    expect(s.messages.last.text, 'Hola Ana, listo.');
    expect(s.messages.last.metadata, {'type': 'attachment_list'});
    expect(repo.jsonCalls, 0);
  });

  test('evento error: se traduce con mapApiError y no hay mensaje de IA', () async {
    final fut = notifier.sendText('hola');
    await _pump();
    final c = repo.controller!;
    c.add(const AssistantStreamStatus(phase: 'thinking', sessionId: 's1'));
    c.add(const AssistantStreamDelta('par'));
    c.add(const AssistantStreamError(ApiException(
        statusCode: 200,
        message: 'busy',
        errorCode: 'AI_PROVIDER_BUSY',
        errorId: 'abcdef123456')));
    await c.close();
    await fut;

    expect(st().isLoading, isFalse);
    expect(st().streamingText, '');
    expect(st().error, 'AI_PROVIDER_BUSY#ref=abcdef12');
    expect(st().messages, hasLength(1));
    expect(repo.jsonCalls, 0);
  });

  test('error de negocio (no 200) al conectar: se muestra, SIN fallback', () async {
    repo.connectError = const ApiException(
        statusCode: 429, message: 'cuota', errorCode: 'QUOTA_EXCEEDED');
    await notifier.sendText('hola');
    expect(st().error, 'QUOTA_EXCEEDED');
    expect(st().isLoading, isFalse);
    expect(repo.jsonCalls, 0);
  });

  test('error de negocio desconocido: muestra el mensaje del backend', () async {
    repo.connectError = const ApiException(
        statusCode: 409, message: 'Algo pasó', errorCode: 'NEW_CODE');
    await notifier.sendText('hola');
    expect(st().error, 'Algo pasó');
  });

  test('fallo de conexión antes de cualquier evento: cae a /ai/chat JSON', () async {
    repo.connectError = _conn;
    await notifier.sendText('hola');
    expect(repo.streamCalls, 1);
    expect(repo.jsonCalls, 1);
    expect(st().messages.last.text, 'json');
    expect(st().sessionId, 'sj');
    expect(st().isLoading, isFalse);
    expect(st().error, isNull);
  });

  test('fallback JSON que también falla: error normal', () async {
    repo.connectError = _conn;
    repo.jsonError = _conn;
    await notifier.sendText('hola');
    expect(st().error, 'CONNECTION_FAILED');
    expect(st().isLoading, isFalse);
  });

  test('conexión caída a media respuesta: error, NO reenvía', () async {
    final fut = notifier.sendText('hola');
    await _pump();
    final c = repo.controller!;
    c.add(const AssistantStreamStatus(phase: 'thinking', sessionId: 's1'));
    await _pump();
    c.addError(_conn);
    await fut;
    expect(st().error, 'CONNECTION_FAILED');
    expect(st().isLoading, isFalse);
    expect(repo.jsonCalls, 0);
  });

  test('stream que cierra sin done: error de conexión', () async {
    final fut = notifier.sendText('hola');
    await _pump();
    final c = repo.controller!;
    c.add(const AssistantStreamStatus(phase: 'thinking', sessionId: 's1'));
    await c.close();
    await fut;
    expect(st().error, 'CONNECTION_FAILED');
    expect(st().isLoading, isFalse);
  });

  test('la etiqueta persiste tras finished y la reemplaza el siguiente started', () async {
    final fut = notifier.sendText('hola');
    await _pump();
    final c = repo.controller!;
    expect(st().toolLabel, isNull); // antes de la primera herramienta: "Pensando"
    expect(st().isLoading, isTrue);
    c.add(const AssistantStreamTool(label: 'A', started: true));
    c.add(const AssistantStreamTool(label: 'A', started: false, ok: true));
    await _pump();
    expect(st().toolLabel, 'A');
    c.add(const AssistantStreamTool(label: 'B', started: true));
    await _pump();
    expect(st().toolLabel, 'B');
    expect(st().toolName, isNull);
    c.add(const AssistantStreamTool(name: 'recall', label: 'C', started: true));
    await _pump();
    expect(st().toolName, 'recall');
    c.add(const AssistantStreamTool(label: 'D', started: true));
    await _pump();
    expect(st().toolName, isNull); // no hereda el nombre anterior
    c.add(const AssistantStreamDone(
        (text: 'ok', sessionId: 's1', metadata: null, aiBackend: null)));
    await c.close();
    await fut;
    expect(st().toolLabel, isNull);
  });

  test('error y cancelled limpian la etiqueta', () async {
    var fut = notifier.sendText('hola');
    await _pump();
    var c = repo.controller!;
    c.add(const AssistantStreamTool(label: 'A', started: true));
    c.add(const AssistantStreamCancelled(sessionId: 's1'));
    await c.close();
    await fut;
    expect(st().toolLabel, isNull);

    fut = notifier.sendText('otra');
    await _pump();
    c = repo.controller!;
    c.add(const AssistantStreamTool(label: 'A', started: true));
    c.add(const AssistantStreamError(_conn));
    await c.close();
    await fut;
    expect(st().toolLabel, isNull);
    expect(st().error, isNotNull);
  });

  test('evento cancelled termina en silencio', () async {
    final fut = notifier.sendText('hola');
    await _pump();
    final c = repo.controller!;
    c.add(const AssistantStreamStatus(phase: 'thinking', sessionId: 's1'));
    c.add(const AssistantStreamCancelled(sessionId: 's1'));
    await c.close();
    await fut;
    expect(st().error, isNull);
    expect(st().isLoading, isFalse);
    expect(st().messages, hasLength(1));
  });

  test('cancelTurn (salir de la pantalla): cierra el SSE y cancela la sesión', () async {
    final fut = notifier.sendText('hola');
    await _pump();
    final c = repo.controller!;
    c.add(const AssistantStreamStatus(phase: 'thinking', sessionId: 's1'));
    c.add(const AssistantStreamDelta('par'));
    await _pump();

    notifier.cancelTurn();
    await _pump();

    expect(repo.streamCancelled, isTrue);
    expect(repo.cancelled, ['s1']);
    expect(st().isLoading, isFalse);
    expect(st().streamingText, '');
    expect(st().error, isNull);

    expect(c.hasListener, isFalse);
    await fut; // sendText no se queda colgado tras cancelar
  });

  test('cancelTurn sin turno en curso no hace nada', () async {
    notifier.cancelTurn();
    expect(repo.cancelled, isEmpty);
  });
}
