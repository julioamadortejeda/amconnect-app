import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/network/api_client.dart';
import 'package:amconnect/core/repositories/policy_repository.dart';

class SupabasePolicyRepository implements PolicyRepository {
  SupabasePolicyRepository(this._client);
  final ApiClient _client;

  @override
  Future<int> getCount() async {
    final res = await _client.get('policies?pageSize=1');
    final wrapper = res['data'] as Map<String, dynamic>;
    // El backend devuelve `total` en la respuesta paginada
    return wrapper['total'] as int? ?? (wrapper['data'] as List?)?.length ?? 0;
  }
}

final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  return SupabasePolicyRepository(ref.read(apiClientProvider));
});
