// Los repositorios que antes recibían "todo" de una vez ahora recorren las
// páginas del contrato único (commitments, notas y pólizas de un cliente).
import 'dart:convert';

import 'package:amconnect/core/network/api_client.dart';
import 'package:amconnect/core/repositories/commitment_repository.dart';
import 'package:amconnect/core/repositories/supabase_note_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _api(MockClientHandler h) => ApiClient(
      client: MockClient(h),
      baseUrl: 'https://api.test',
      headersBuilder: () async => {'Content-Type': 'application/json'},
    );

http.Response _page(List<Map<String, dynamic>> rows, {required bool hasMore}) =>
    http.Response(
        jsonEncode({
          'success': true,
          'data': {'data': rows, 'page': 1, 'pageSize': 100, 'hasMore': hasMore},
        }),
        200);

Map<String, dynamic> _note(String id) =>
    {'id': id, 'content': 'c', 'created_at': '2026-11-01T00:00:00Z'};

Map<String, dynamic> _commitment(String id) =>
    {'id': id, 'label': 'L$id', 'quote': 'q'};

void main() {
  test('notas de contacto: pide todas las páginas', () async {
    final seen = <String>[];
    final repo = SupabaseNoteRepository(_api((req) async {
      seen.add('${req.url.path}?${req.url.query}');
      return req.url.queryParameters['page'] == '1'
          ? _page([_note('a')], hasMore: true)
          : _page([_note('b')], hasMore: false);
    }));
    final notes = await repo.getByContactId('c1');
    expect(notes.map((n) => n.id), ['a', 'b']);
    expect(seen, [
      '/contacts/c1/notes?page=1&pageSize=100',
      '/contacts/c1/notes?page=2&pageSize=100',
    ]);
  });

  test('notas de póliza y recordatorio usan su ruta con paginación', () async {
    final paths = <String>[];
    final repo = SupabaseNoteRepository(_api((req) async {
      paths.add(req.url.path);
      return _page([_note('a')], hasMore: false);
    }));
    await repo.getByPolicyId('p1');
    await repo.getByReminderId('r1');
    expect(paths, ['/policies/p1/notes', '/reminders/r1/notes']);
  });

  test('searchNotes manda page/pageSize/search y lee hasMore del servidor', () async {
    late Uri url;
    final repo = SupabaseNoteRepository(_api((req) async {
      url = req.url;
      return _page([_note('a')], hasMore: true);
    }));
    final res = await repo.searchNotes(page: 2, pageSize: 20, query: 'pó liza');
    expect(url.queryParameters, {'page': '2', 'pageSize': '20', 'search': 'pó liza'});
    expect(res.items.length, 1);
    expect(res.hasMore, isTrue);
  });

  test('compromisos: filtros + páginas, y la búsqueda conserva query', () async {
    final urls = <Uri>[];
    final repo = SupabaseCommitmentRepository(_api((req) async {
      urls.add(req.url);
      return req.url.queryParameters['page'] == '1'
          ? _page([_commitment('a')], hasMore: true)
          : _page([_commitment('b')], hasMore: false);
    }));
    final open = await repo.getOpen(contactId: 'c1', from: DateTime(2026, 11, 1));
    expect(open.map((c) => c.id), ['a', 'b']);
    expect(urls.first.queryParameters,
        {'from': '2026-11-01', 'contactId': 'c1', 'page': '1', 'pageSize': '100'});

    urls.clear();
    await repo.search('cotización');
    expect(urls.first.queryParameters['query'], 'cotización');
    expect(urls.first.queryParameters['pageSize'], '100');
  });
}
