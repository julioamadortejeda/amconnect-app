import 'dart:convert';
import 'dart:io';

import 'package:amconnect/core/network/api_client.dart';
import 'package:amconnect/features/assistant/data/assistant_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AssistantRepository _repo(MockClientHandler h) => AssistantRepository(ApiClient(
      client: MockClient(h),
      baseUrl: 'https://api.test',
      headersBuilder: () async => {'Content-Type': 'application/json'},
    ));

http.Response _sse(String body) =>
    http.Response(body, 200, headers: {'content-type': 'text/event-stream'});

const _full = '''
id: 1
event: status
data: {"phase":"thinking","sessionId":"s1"}

id: 2
event: tool
data: {"label":"Buscando cliente","state":"started"}

id: 3
event: tool
data: {"label":"Buscando cliente","state":"finished","ok":true}

id: 4
event: weird
data: {"x":1}

id: 5
event: delta
data: {"text":"Hola"}

id: 6
event: done
data: {"text":"Hola Ana","sessionId":"s1","metadata":{"type":"attachment_list"},"aiBackend":"vertex","usage":{}}

''';

void main() {
  test('mapea eventos tipados y descarta desconocidos', () async {
    final repo = _repo((_) async => _sse(_full));
    final events = await repo.sendMessageStream('hola').toList();
    expect(events.map((e) => e.runtimeType), [
      AssistantStreamStatus,
      AssistantStreamTool,
      AssistantStreamTool,
      AssistantStreamDelta,
      AssistantStreamDone,
    ]);
    expect((events[0] as AssistantStreamStatus).sessionId, 's1');
    expect((events[1] as AssistantStreamTool).started, isTrue);
    expect((events[2] as AssistantStreamTool).ok, isTrue);
    final done = (events[4] as AssistantStreamDone).result;
    expect(done.text, 'Hola Ana');
    expect(done.metadata, {'type': 'attachment_list'});
    expect(done.aiBackend, 'vertex');
  });

  test('evento error y cancelled', () async {
    final repo = _repo((_) async => _sse(
        'event: error\ndata: {"errorCode":"AI_PROVIDER_BUSY","error":"busy","errorId":"abc"}\n\n'
        'event: cancelled\ndata: {"sessionId":"s1","modelCalls":1}\n\n'));
    final ev = await repo.sendMessageStream('x').toList();
    final err = (ev[0] as AssistantStreamError).error;
    expect(err.errorCode, 'AI_PROVIDER_BUSY');
    expect(err.errorId, 'abc');
    expect((ev[1] as AssistantStreamCancelled).sessionId, 's1');
  });

  test('data malformada se ignora sin romper el stream', () async {
    final repo = _repo((_) async =>
        _sse('event: delta\ndata: {no-json\n\nevent: delta\ndata: {"text":"ok"}\n\n'));
    final ev = await repo.sendMessageStream('x').toList();
    expect(ev, hasLength(1));
    expect((ev.single as AssistantStreamDelta).text, 'ok');
  });

  test('no 200: lanza ApiException con errorCode (igual que /ai/chat)', () async {
    final repo = _repo((_) async => http.Response(
        jsonEncode({'success': false, 'error': 'cuota', 'errorCode': 'QUOTA_EXCEEDED'}), 429));
    await expectLater(
      repo.sendMessageStream('x').toList(),
      throwsA(isA<ApiException>()
          .having((e) => e.errorCode, 'code', 'QUOTA_EXCEEDED')
          .having((e) => e.statusCode, 'status', 429)),
    );
  });

  test('fallo al conectar: CONNECTION_FAILED', () async {
    final repo = _repo((_) async => throw const SocketException('down'));
    await expectLater(
      repo.sendMessageStream('x').toList(),
      throwsA(isA<ApiException>().having((e) => e.errorCode, 'code', kConnectionFailedCode)),
    );
  });

  test('manda mismo body y pide event-stream', () async {
    late http.Request seen;
    final repo = _repo((r) async {
      seen = r;
      return _sse('');
    });
    await repo.sendMessageStream('hola', sessionId: 's9').toList();
    expect(seen.url.path, '/ai/chat/stream');
    expect(seen.headers['Accept'], 'text/event-stream');
    expect(jsonDecode(seen.body), {'message': 'hola', 'sessionId': 's9'});
  });

  test('sendMessage (JSON) sigue funcionando', () async {
    final repo = _repo((r) async {
      expect(r.url.path, '/ai/chat');
      return http.Response(
          jsonEncode({'data': {'text': 't', 'sessionId': 's', 'aiBackend': 'studio'}}), 200);
    });
    final r = await repo.sendMessage('hola');
    expect((r.text, r.sessionId, r.metadata, r.aiBackend), ('t', 's', null, 'studio'));
  });
}
