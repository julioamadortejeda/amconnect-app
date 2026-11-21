import 'dart:convert';

import 'package:amconnect/core/network/api_client.dart';
import 'package:amconnect/core/repositories/supabase_reminder_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _reminder(String id, {String status = 'CREATED'}) => {
      'id': id,
      'title': 'R $id',
      'status': {'id': 's', 'code': status, 'name': status},
    };

SupabaseReminderRepository _repo(MockClientHandler handler) =>
    SupabaseReminderRepository(ApiClient(
      client: MockClient(handler),
      baseUrl: 'https://api.test',
      headersBuilder: () async => {'Content-Type': 'application/json'},
    ));

void main() {
  test('markDone usa PATCH reminders/:id/done sin cuerpo', () async {
    late http.Request seen;
    final repo = _repo((req) async {
      seen = req;
      return http.Response(jsonEncode({'success': true, 'data': _reminder('r1', status: 'DONE')}), 200);
    });
    final r = await repo.markDone('r1');
    expect(seen.method, 'PATCH');
    expect(seen.url.path, '/reminders/r1/done');
    expect(seen.body, isEmpty);
    expect(r?.done, isTrue);
  });

  test('markDone propaga el error (la UI revierte)', () async {
    final repo = _repo((_) async => http.Response(
        jsonEncode({'success': false, 'error': 'x', 'errorCode': 'RESOURCE_NOT_FOUND'}), 404));
    await expectLater(repo.markDone('nope'), throwsA(isA<ApiException>()));
  });

  test('getAll recorre todas las páginas y quita duplicados', () async {
    final pages = <String>[];
    final repo = _repo((req) async {
      final page = req.url.queryParameters['page']!;
      pages.add(page);
      final body = switch (page) {
        '1' => {'data': [_reminder('a'), _reminder('b')], 'hasMore': true},
        '2' => {'data': [_reminder('b'), _reminder('c')], 'hasMore': true},
        _ => {'data': [_reminder('d')], 'hasMore': false},
      };
      expect(req.url.queryParameters['pageSize'], '100');
      return http.Response(jsonEncode({'success': true, 'data': body}), 200);
    });
    final all = await repo.getAll();
    expect(pages, ['1', '2', '3']);
    expect(all.map((r) => r.id), ['a', 'b', 'c', 'd']);
  });

  test('getByPolicy conserva el filtro al paginar', () async {
    final repo = _repo((req) async {
      expect(req.url.queryParameters['policyId'], 'p1');
      return http.Response(
          jsonEncode({'success': true, 'data': {'data': [_reminder('a')], 'hasMore': false}}), 200);
    });
    expect((await repo.getByPolicy('p1')).length, 1);
  });
}
