import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/policy.dart';
import '../network/api_client.dart';
import 'policy_repository.dart';

class SupabasePolicyRepository implements PolicyRepository {
  SupabasePolicyRepository(this._client);
  final ApiClient _client;

  @override
  Future<int> getCount() async {
    final res = await _client.get('policies?pageSize=1');
    final wrapper = res['data'] as Map<String, dynamic>;
    return wrapper['total'] as int? ?? (wrapper['data'] as List?)?.length ?? 0;
  }

  @override
  Future<List<Policy>> getByContactId(String contactId) async {
    final res = await _client.get('contacts/$contactId/policies');
    final items = res['data'] as List<dynamic>;
    return items
        .map((e) => Policy.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  return SupabasePolicyRepository(ref.read(apiClientProvider));
});
