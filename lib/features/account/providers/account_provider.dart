import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/agent_profile.dart';
import '../../../core/models/subscription_info.dart';
import '../../../core/repositories/agent_repository.dart';
import '../../../core/repositories/supabase_agent_repository.dart';
import '../../../core/repositories/supabase_subscription_repository.dart';
import '../../../core/repositories/subscription_repository.dart';
import '../../home/providers/home_provider.dart';

class AgentProfileNotifier extends AsyncNotifier<AgentProfile> {
  late AgentRepository _repo;

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

class SubscriptionInfoNotifier extends AsyncNotifier<SubscriptionInfo> {
  late SubscriptionRepository _repo;
  RealtimeChannel? _realtimeChannel;

  @override
  Future<SubscriptionInfo> build() async {
    _repo = ref.read(subscriptionRepositoryProvider);
    _listenRealtime();
    return _repo.getInfo();
  }

  void _listenRealtime() {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeChannel = client
        .channel('public:agents:subscription_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'agents',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (_) {
            ref.invalidateSelf();
          },
        )
        .subscribe((status, error) {
          debugPrint('[RT:agents:subscription] $status $error');
        });

    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getInfo());
  }
}

final subscriptionInfoProvider =
    AsyncNotifierProvider<SubscriptionInfoNotifier, SubscriptionInfo>(SubscriptionInfoNotifier.new);

/// True cuando el perfil y la suscripción ya cargaron.
final accountReadyProvider = FutureProvider<bool>((ref) async {
  await Future.wait([
    ref.watch(agentProfileProvider.future),
    ref.watch(subscriptionInfoProvider.future),
  ]);
  return true;
});
