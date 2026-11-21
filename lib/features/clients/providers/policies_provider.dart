import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/policy.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/repositories/policy_repository.dart';
import '../../../core/repositories/supabase_policy_repository.dart';
import 'client_list_state_provider.dart';

class PoliciesNotifier extends AsyncNotifier<List<Policy>> {
  late PolicyRepository _repo;
  RealtimeChannel? _channel;

  @override
  Future<List<Policy>> build() async {
    _repo = ref.read(policyRepositoryProvider);
    final result = await _repo.getAll(page: 1);
    ref.read(policiesPageInfoProvider.notifier).set(
          ListPageInfo(page: 1, hasMore: result.hasMore),
        );

    // Igual que en ClientsNotifier: si hay búsqueda activa, cargar todo lo
    // que falte para que el filtro client-side no pierda resultados.
    ref.listen(policySearchProvider, (prev, next) {
      if (next.isNotEmpty) unawaited(loadAll());
    });

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'agent_id',
        value: userId,
      );
      _channel = Supabase.instance.client
          .channel('policies:global:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'policies',
            filter: filter,
            callback: (p) => _onInsert(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'policies',
            filter: filter,
            callback: (p) => _onUpdate(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'policies',
            filter: filter,
            callback: (p) => _onDelete(p.oldRecord),
          )
          .subscribe((status, error) {
            debugPrint('[RT:policies_global] $status $error');
          });

      ref.onDispose(() { _channel?.unsubscribe(); });
    }

    return result.items;
  }

  /// Petición de página en vuelo. `loadMore` concurrentes la comparten en vez
  /// de regresar al instante: `loadAll` esperaba un `loadMore` que no hacía
  /// nada, el `while` giraba solo con microtasks y congelaba la UI.
  Future<bool>? _loadMoreInFlight;

  /// Carga la siguiente página y la añade a la lista ya cargada.
  /// Devuelve `false` si la petición falló (sin red, timeout…).
  Future<bool> loadMore() {
    final inFlight = _loadMoreInFlight;
    if (inFlight != null) return inFlight;
    if (!ref.read(policiesPageInfoProvider).hasMore) return Future.value(true);
    final future = _fetchNextPage().whenComplete(() => _loadMoreInFlight = null);
    _loadMoreInFlight = future;
    return future;
  }

  Future<bool> _fetchNextPage() async {
    final pageState = ref.read(policiesPageInfoProvider);
    ref.read(policiesPageInfoProvider.notifier).set(
          pageState.copyWith(isLoadingMore: true),
        );
    try {
      final nextPage = pageState.page + 1;
      final result = await _repo.getAll(page: nextPage);
      final existing = state.value ?? [];
      final existingIds = existing.map((p) => p.id).toSet();
      final newItems = result.items.where((p) => !existingIds.contains(p.id));
      state = AsyncData([...existing, ...newItems]);
      ref.read(policiesPageInfoProvider.notifier).set(
            ListPageInfo(page: nextPage, hasMore: result.hasMore),
          );
      return true;
    } catch (_) {
      // Falla de página: se deja `hasMore` como estaba para que el scroll
      // pueda reintentar; quien itera (`loadAll`) se detiene con el `false`.
      ref.read(policiesPageInfoProvider.notifier).set(
            pageState.copyWith(isLoadingMore: false),
          );
      return false;
    }
  }

  /// Carga todas las páginas restantes de una sola vez — usado cuando hay
  /// una búsqueda activa (ver `build`).
  ///
  /// Se detiene al primer fallo (sin red no martilla al backend) y si una
  /// vuelta no avanzó de página (defensa contra un bucle sin progreso).
  Future<void> loadAll() async {
    while (ref.read(policiesPageInfoProvider).hasMore) {
      final before = ref.read(policiesPageInfoProvider).page;
      final ok = await loadMore();
      if (!ok) return;
      final after = ref.read(policiesPageInfoProvider);
      if (after.hasMore && after.page == before) return;
    }
  }

  /// Pull-to-refresh: vuelve a la página 1 sin pasar por `AsyncLoading`.
  /// Devuelve la clave de error (para `translateError`) o null si salió bien.
  Future<String?> refresh() async {
    try {
      final result = await _repo.getAll(page: 1);
      state = AsyncData(result.items);
      ref.read(policiesPageInfoProvider.notifier).set(
            ListPageInfo(page: 1, hasMore: result.hasMore),
          );
      // Con búsqueda activa el filtro es client-side: hay que volver a bajar
      // el resto, igual que al empezar a buscar.
      if (ref.read(policySearchProvider).isNotEmpty) unawaited(loadAll());
      return null;
    } catch (e) {
      return mapApiError(e);
    }
  }

  Future<void> _onInsert(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (state.asData?.value.any((p) => p.id == id) == true) return;
    try {
      final policy = await _repo.getById(id);
      state = AsyncData([...state.requireValue, policy]);
    } catch (_) {
      // fire-and-forget: eco de Realtime, se autocorrige con el próximo evento o refetch
    }
  }

  Future<void> _onUpdate(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (row['is_active'] == false) {
      state = AsyncData(state.requireValue.where((p) => p.id != id).toList());
      return;
    }
    try {
      final policy = await _repo.getById(id);
      state = AsyncData([
        for (final p in state.requireValue) if (p.id == id) policy else p,
      ]);
    } catch (_) {
      // fire-and-forget: eco de Realtime, se autocorrige con el próximo evento o refetch
    }
  }

  void _onDelete(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    if (id == null) return;
    state = AsyncData(state.requireValue.where((p) => p.id != id).toList());
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = AsyncData(state.requireValue.where((p) => p.id != id).toList());
  }
}

final policiesProvider =
    AsyncNotifierProvider<PoliciesNotifier, List<Policy>>(PoliciesNotifier.new);
