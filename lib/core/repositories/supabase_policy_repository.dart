import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/policy.dart';
import '../network/api_client.dart';
import '../network/api_envelope.dart';
import 'policy_repository.dart';

class SupabasePolicyRepository implements PolicyRepository {
  SupabasePolicyRepository(this._client);
  final ApiClient _client;

  @override
  Future<int> getCount() async {
    final res = await _client.get('policies?pageSize=1');
    final page = PageResponse.fromEnvelope(res, Policy.fromJson);
    return page.total ?? page.items.length;
  }

  @override
  Future<List<Policy>> getByContactId(String contactId) {
    // La ficha del cliente muestra todas sus pólizas: se recorren las páginas.
    return fetchAllPages(
      fetch: (page, size) =>
          _client.get('contacts/$contactId/policies?page=$page&pageSize=$size'),
      parse: Policy.fromJson,
      idOf: (p) => p.id,
    );
  }

  @override
  Future<({List<Policy> items, bool hasMore})> getAll({
    int page = 1,
    int pageSize = 30,
  }) async {
    final res = await _client.get('policies?page=$page&pageSize=$pageSize');
    final result = PageResponse.fromEnvelope(res, Policy.fromJson);
    return (items: result.items, hasMore: result.hasMore);
  }

  @override
  Future<Policy> getById(String id) async {
    final res = await _client.get('policies/$id');
    final data = res['data'] as Map<String, dynamic>;
    return Policy.fromJson(data['policy'] as Map<String, dynamic>);
  }

  @override
  Future<Policy> create(Map<String, dynamic> data) async {
    final res = await _client.post('policies', body: data);
    return Policy.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<Policy> update(String id, Map<String, dynamic> data) async {
    final res = await _client.patch('policies/$id', body: data);
    return Policy.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    await _client.delete('policies/$id');
  }
}

final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  return SupabasePolicyRepository(ref.read(apiClientProvider));
});
