import 'dart:async';
import 'dart:convert';

import 'package:amconnect/core/network/sse_parser.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<SseEvent>> _parse(List<List<int>> chunks) =>
    Stream.fromIterable(chunks).transform(const SseParser()).toList();

List<int> _b(String s) => utf8.encode(s);

void main() {
  test('evento simple con id, event y data', () async {
    final ev = await _parse([_b('id: 1\nevent: status\ndata: {"a":1}\n\n')]);
    expect(ev, hasLength(1));
    expect(ev.single.id, '1');
    expect(ev.single.event, 'status');
    expect(ev.single.data, '{"a":1}');
  });

  test('chunks partidos en cualquier byte (incluso en la frontera del evento)', () async {
    const raw = 'id: 1\nevent: delta\ndata: {"text":"hola"}\n\nid: 2\nevent: done\ndata: {}\n\n';
    final bytes = _b(raw);
    for (var cut = 1; cut < bytes.length; cut++) {
      final ev = await _parse([bytes.sublist(0, cut), bytes.sublist(cut)]);
      expect(ev.map((e) => e.event), ['delta', 'done'], reason: 'corte en $cut');
      expect(ev.first.data, '{"text":"hola"}');
    }
  });

  test('un byte por chunk', () async {
    final bytes = _b('event: a\ndata: x\n\nevent: b\ndata: y\n\n');
    final ev = await _parse([
      for (final x in bytes) [x]
    ]);
    expect(ev.map((e) => '${e.event}:${e.data}'), ['a:x', 'b:y']);
  });

  test('UTF-8 multibyte partido entre chunks', () async {
    final bytes = _b('event: delta\ndata: {"text":"añejo ✓"}\n\n');
    final cut = bytes.indexOf(0xC3) + 1; // a media ñ
    final ev = await _parse([bytes.sublist(0, cut), bytes.sublist(cut)]);
    expect(ev.single.data, '{"text":"añejo ✓"}');
  });

  test('data multilínea se une con \\n', () async {
    final ev = await _parse([_b('event: x\ndata: uno\ndata: dos\ndata:tres\n\n')]);
    expect(ev.single.data, 'uno\ndos\ntres');
  });

  test('comentarios y heartbeats se ignoran', () async {
    final ev = await _parse([_b(': keep-alive\n\n: otro\nevent: x\n: medio\ndata: 1\n\n')]);
    expect(ev, hasLength(1));
    expect(ev.single.data, '1');
  });

  test('campos desconocidos y retry se ignoran; evento sin data no se emite', () async {
    final ev = await _parse([_b('retry: 3000\nfoo: bar\nevent: solo\n\nevent: y\ndata: 1\n\n')]);
    expect(ev, hasLength(1));
    expect(ev.single.event, 'y');
  });

  test('CRLF, incluso con \\r y \\n en chunks distintos', () async {
    final ev = await _parse([
      _b('event: a\r\ndata: 1\r'),
      _b('\n\r\nevent: b\r\ndata: 2\r\n\r\n'),
    ]);
    expect(ev.map((e) => e.data), ['1', '2']);
    expect(ev.map((e) => e.event), ['a', 'b']);
  });

  test('evento sin nombre (event null) y valor sin espacio tras ":"', () async {
    final ev = await _parse([_b('data:sin-espacio\n\n')]);
    expect(ev.single.event, isNull);
    expect(ev.single.data, 'sin-espacio');
  });

  test('un evento incompleto al cerrar la conexión se descarta', () async {
    final ev = await _parse([_b('event: a\ndata: 1\n\nevent: b\ndata: 2')]);
    expect(ev.map((e) => e.event), ['a']);
  });

  test('cancelar la suscripción cancela la fuente', () async {
    var cancelled = false;
    final src = StreamController<List<int>>(onCancel: () => cancelled = true);
    final sub = src.stream.transform(const SseParser()).listen((_) {});
    await sub.cancel();
    expect(cancelled, isTrue);
  });
}
