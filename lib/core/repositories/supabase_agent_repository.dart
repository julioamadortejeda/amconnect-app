import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import 'agent_repository.dart';

class SupabaseAgentRepository implements AgentRepository {
  SupabaseAgentRepository(this._client);
  final ApiClient _client;

  @override
  Future<String> getMyName() async {
    final res = await _client.get('agents/me');
    final data = res['data'] as Map<String, dynamic>;
    return data['fullName'] as String? ?? '';
  }

  @override
  Future<void> registerDeviceToken({required String token, required String platform}) async {
    await _client.post('agents/device-tokens', body: {
      'token': token,
      'platform': platform,
    });
  }

  @override
  Future<void> deregisterDeviceToken({required String token}) async {
    await _client.delete('agents/device-tokens', body: {
      'token': token,
    });
  }
}

final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return SupabaseAgentRepository(ref.read(apiClientProvider));
});
