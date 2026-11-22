import 'dart:async';
import 'dart:convert';

/// Un evento Server-Sent Events ya ensamblado.
class SseEvent {
  const SseEvent({this.id, this.event, required this.data});

  final String? id;

  /// Nombre del evento (`event:`); null si el servidor no lo mandó.
  final String? event;

  /// Líneas `data:` unidas con `\n`.
  final String data;

  @override
  String toString() => 'SseEvent(id: $id, event: $event, data: $data)';
}

/// Parser de `text/event-stream` (spec WHATWG), sin dependencias de red.
///
/// Se usa como `bytes.transform(const SseParser())`. Maneja chunks partidos en
/// cualquier punto (incluso a media línea, a media secuencia UTF-8 o entre
/// `\r` y `\n`), data multilínea, comentarios (`:`) y campos desconocidos
/// (`retry:` y otros se ignoran). Un evento solo se emite al llegar la línea
/// en blanco y si trae al menos una línea `data:`.
class SseParser extends StreamTransformerBase<List<int>, SseEvent> {
  const SseParser();

  @override
  Stream<SseEvent> bind(Stream<List<int>> stream) {
    late StreamController<SseEvent> controller;
    StreamSubscription<String>? sub;

    var pending = ''; // texto sin terminar de línea
    var lastWasCr = false; // el chunk anterior terminó en \r
    String? id;
    String? event;
    final data = <String>[];

    void dispatch() {
      if (data.isNotEmpty) {
        controller.add(SseEvent(id: id, event: event, data: data.join('\n')));
      }
      event = null;
      data.clear();
      // `id` persiste entre eventos según la spec (last event id).
    }

    void handleLine(String line) {
      if (line.isEmpty) {
        dispatch();
        return;
      }
      if (line.startsWith(':')) return; // comentario / heartbeat
      final i = line.indexOf(':');
      final field = i < 0 ? line : line.substring(0, i);
      var value = i < 0 ? '' : line.substring(i + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      switch (field) {
        case 'data':
          data.add(value);
        case 'event':
          event = value;
        case 'id':
          id = value;
        default:
          break; // retry y desconocidos
      }
    }

    void onText(String chunk) {
      var text = chunk;
      if (lastWasCr) {
        lastWasCr = false;
        if (text.startsWith('\n')) text = text.substring(1);
      }
      if (text.isEmpty) return;
      final buf = pending + text;
      pending = '';
      var start = 0;
      for (var i = 0; i < buf.length; i++) {
        final c = buf.codeUnitAt(i);
        if (c == 0x0A || c == 0x0D) {
          handleLine(buf.substring(start, i));
          if (c == 0x0D) {
            if (i + 1 < buf.length) {
              if (buf.codeUnitAt(i + 1) == 0x0A) i++;
            } else {
              lastWasCr = true;
            }
          }
          start = i + 1;
        }
      }
      pending = buf.substring(start);
    }

    controller = StreamController<SseEvent>(
      onListen: () {
        sub = stream.cast<List<int>>().transform(utf8.decoder).listen(
              onText,
              onError: controller.addError,
              onDone: controller.close, // evento incompleto se descarta (spec)
            );
      },
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }
}
