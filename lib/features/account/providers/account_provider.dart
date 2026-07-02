import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/agent_profile.dart';
import '../../../core/models/subscription_info.dart';
import '../../../core/repositories/agent_repository.dart';
import '../../../core/repositories/supabase_agent_repository.dart';
import '../../../core/repositories/supabase_subscription_repository.dart';
import '../../home/providers/home_provider.dart';

class AgentProfileNotifier extends AsyncNotifier<AgentProfile> {
  late final AgentRepository _repo;

  @override
  Future<AgentProfile> build() async {
    _repo = ref.read(agentRepositoryProvider);
    return _repo.getMe();
  }

  Future<void> updateProfile({String? fullName, String? phone}) async {
    final updated = await _repo.updateMe(fullName: fullName, phone: phone);
    state = AsyncData(updated);
    ref.invalidate(agentNameProvider);
  }
}

final agentProfileProvider =
    AsyncNotifierProvider<AgentProfileNotifier, AgentProfile>(AgentProfileNotifier.new);

final subscriptionInfoProvider = FutureProvider<SubscriptionInfo>((ref) {
  return ref.read(subscriptionRepositoryProvider).getInfo();
});

/// True cuando el perfil y la suscripción ya cargaron.
final accountReadyProvider = FutureProvider<bool>((ref) async {
  await Future.wait([
    ref.watch(agentProfileProvider.future),
    ref.watch(subscriptionInfoProvider.future),
  ]);
  return true;
});
