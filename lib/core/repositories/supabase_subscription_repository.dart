import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_info.dart';
import '../network/api_client.dart';
import 'subscription_repository.dart';

class SupabaseSubscriptionRepository implements SubscriptionRepository {
  SupabaseSubscriptionRepository(this._client);
  final ApiClient _client;

  @override
  Future<SubscriptionInfo> getInfo() async {
    final res = await _client.get('subscription');
    return SubscriptionInfo.fromJson(res['data'] as Map<String, dynamic>);
  }
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SupabaseSubscriptionRepository(ref.read(apiClientProvider));
});
