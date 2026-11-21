import 'package:amconnect/core/network/api_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _page(List<String> ids, {required bool hasMore, int? total}) => {
      'success': true,
      'data': {
        'data': [for (final id in ids) {'id': id}],
        'page': 1,
        'pageSize': 100,
        'hasMore': hasMore,
        if (total != null) 'total': total,
      },
    };

String _id(Map<String, dynamic> j) => j['id'] as String;

void main() {
  test('unwrapData devuelve el objeto de data', () {
    expect(unwrapData({'success': true, 'data': {'a': 1}}), {'a': 1});
  });

  test('PageResponse lee items, hasMore y total del contrato único', () {
    final p = PageResponse.fromEnvelope(_page(['a', 'b'], hasMore: true, total: 9), _id);
    expect(p.items, ['a', 'b']);
    expect(p.hasMore, isTrue);
    expect(p.total, 9);
  });

  test('PageResponse: sin total (búsqueda) queda en null y hasMore faltante es false', () {
    final p = PageResponse.fromEnvelope({
      'success': true,
      'data': {'data': <dynamic>[]}
    }, _id);
    expect(p.items, isEmpty);
    expect(p.total, isNull);
    expect(p.hasMore, isFalse);
  });

  test('fetchAllPages recorre hasMore, pide pageSize 100 y quita duplicados', () async {
    final asked = <(int, int)>[];
    final all = await fetchAllPages<String>(
      fetch: (page, size) async {
        asked.add((page, size));
        return switch (page) {
          1 => _page(['a', 'b'], hasMore: true),
          2 => _page(['b', 'c'], hasMore: true),
          _ => _page(['d'], hasMore: false),
        };
      },
      parse: _id,
      idOf: (s) => s,
    );
    expect(asked, [(1, 100), (2, 100), (3, 100)]);
    expect(all, ['a', 'b', 'c', 'd']);
  });

  test('fetchAllPages se detiene en una página vacía aunque hasMore sea true', () async {
    var calls = 0;
    final all = await fetchAllPages<String>(
      fetch: (page, size) async {
        calls++;
        return _page(const [], hasMore: true);
      },
      parse: _id,
    );
    expect(all, isEmpty);
    expect(calls, 1);
  });

  test('fetchAllPages respeta el freno maxPages', () async {
    var calls = 0;
    await fetchAllPages<String>(
      fetch: (page, size) async {
        calls++;
        return _page(['p$page'], hasMore: true);
      },
      parse: _id,
      maxPages: 3,
    );
    expect(calls, 3);
  });
}
