import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/agent_profile.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/locale_provider.dart';
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
    final me = await _repo.getMe();
    // D-024: el backend necesita el idioma del asesor (push, correos). Si nunca
    // se guardó, se sube el que la app está usando. Sin await: no retrasa la
    // carga del perfil ni lo rompe si falla.
    if (me.locale == null) unawaited(_pushLocale(_currentLanguage()));
    return me;
  }

  String _currentLanguage() => resolveLanguageCode(
        ref.read(localeProvider),
        PlatformDispatcher.instance.locale,
      );

  Future<void> _pushLocale(String code) async {
    try {
      await _repo.updateLocale(code);
    } on ApiException {
      // Fire-and-forget: se reintenta en la próxima carga mientras siga null.
    }
  }

  /// Cambia el idioma de la app y lo guarda en el backend. El cambio local
  /// es inmediato; si el PATCH falla la app queda en el idioma elegido.
  Future<void> setLanguage(String code) async {
    await ref.read(localeProvider.notifier).setLanguage(code);
    await _pushLocale(code);
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(locale: code));
  }

  /// Registra la aceptación de la versión vigente del Aviso de Privacidad.
  /// Lanza `ApiException` si el backend rechaza (ej. versión ya no vigente).
  Future<void> acceptPrivacy({required bool acceptedNotice, required bool acceptedSensitive}) async {
    final current = state.value;
    if (current == null) return;
    final privacy = await _repo.acceptPrivacy(current.privacy.currentVersion,
        acceptedNotice: acceptedNotice, acceptedSensitive: acceptedSensitive);
    state = AsyncData(current.copyWith(privacy: privacy));
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
  RealtimeChannel? _agentsChannel;
  RealtimeChannel? _usageChannel;

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

    _agentsChannel = client
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

    // El uso del plan (chat_count/ingestion_count) vive en agent_monthly_usage,
    // no en agents — canal propio (mismo patrón que contacts/policies/
    // reminders), no compartido con el de arriba: mezclar dos tablas en un
    // mismo canal hacía que el binding de "update" de una pisara al de la otra.
    final usageFilter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'agent_id',
      value: userId,
    );
    _usageChannel = client
        .channel('public:agent_monthly_usage:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'agent_monthly_usage',
          filter: usageFilter,
          callback: (_) {
            ref.invalidateSelf();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'agent_monthly_usage',
          filter: usageFilter,
          callback: (_) {
            ref.invalidateSelf();
          },
        )
        .subscribe((status, error) {
          debugPrint('[RT:agent_monthly_usage:subscription] $status $error');
        });

    ref.onDispose(() {
      _agentsChannel?.unsubscribe();
      _usageChannel?.unsubscribe();
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
