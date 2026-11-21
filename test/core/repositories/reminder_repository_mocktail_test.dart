import 'package:amconnect/core/network/api_client.dart';
import 'package:amconnect/core/repositories/supabase_reminder_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

Map<String, dynamic> _reminder(String id) => {
      'id': id,
      'title': 'R $id',
      'status': {'id': 's', 'code': 'CREATED', 'name': 'CREATED'},
    };

Map<String, dynamic> _page(List<String> ids, {required bool hasMore}) => {
      'success': true,
      'data': {'data': ids.map(_reminder).toList(), 'hasMore': hasMore},
    };

void main() {
  late MockApiClient api;
  late ProviderContainer container;

  setUp(() {
    api = MockApiClient();
    container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
  });

  test('el repositorio usa el ApiClient inyectado por el provider', () async {
    when(() => api.get(any())).thenAnswer((_) async => _page(['a'], hasMore: false));

    final all = await container.read(reminderRepositoryProvider).getAll();

    expect(all.map((r) => r.id), ['a']);
    verify(() => api.get('reminders?page=1&pageSize=100')).called(1);
  });

  test('getAll pide páginas hasta que hasMore es false y quita duplicados', () async {
    when(() => api.get('reminders?page=1&pageSize=100'))
        .thenAnswer((_) async => _page(['a', 'b'], hasMore: true));
    when(() => api.get('reminders?page=2&pageSize=100'))
        .thenAnswer((_) async => _page(['b', 'c'], hasMore: false));

    final all = await container.read(reminderRepositoryProvider).getAll();

    expect(all.map((r) => r.id), ['a', 'b', 'c']);
    verifyNever(() => api.get('reminders?page=3&pageSize=100'));
  });

  test('getAll corta si el backend responde hasMore con página vacía', () async {
    when(() => api.get(any())).thenAnswer((_) async => _page([], hasMore: true));

    final all = await container.read(reminderRepositoryProvider).getAll();

    expect(all, isEmpty);
    verify(() => api.get(any())).called(1);
  });

  test('getByPolicy conserva el filtro con & al paginar', () async {
    when(() => api.get(any())).thenAnswer((_) async => _page(['a'], hasMore: false));

    await container.read(reminderRepositoryProvider).getByPolicy('p1');

    verify(() => api.get('reminders?policyId=p1&page=1&pageSize=100')).called(1);
  });

  test('el ApiException del cliente llega intacto a quien llama', () async {
    when(() => api.get(any())).thenThrow(const ApiException(
      statusCode: 401,
      message: 'expired',
      errorCode: 'SESSION_EXPIRED',
    ));

    await expectLater(
      container.read(reminderRepositoryProvider).getAll(),
      throwsA(isA<ApiException>().having((e) => e.errorCode, 'errorCode', 'SESSION_EXPIRED')),
    );
  });
}
