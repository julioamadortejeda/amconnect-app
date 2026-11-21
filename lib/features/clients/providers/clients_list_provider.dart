import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/contact.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/repositories/contact_repository.dart';
import '../../../core/repositories/supabase_contact_repository.dart';
import 'client_list_state_provider.dart';

class ClientsNotifier extends AsyncNotifier<List<Contact>> {
  late ContactRepository _repo;
  RealtimeChannel? _channel;

  @override
  Future<List<Contact>> build() async {
    _repo = ref.read(contactRepositoryProvider);
    final result = await _repo.getAll(page: 1);
    ref.read(clientsPageInfoProvider.notifier).set(
          ListPageInfo(page: 1, hasMore: result.hasMore),
        );

    // Si el asesor ya está buscando (o empieza a buscar), cargamos todas las
    // páginas restantes — el filtro `matchesQuery` es client-side, así que
    // sin esto la búsqueda "no encontraría" clientes en páginas no cargadas.
    ref.listen(clientSearchProvider, (prev, next) {
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
          .channel('contacts:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'contacts',
            filter: filter,
            callback: (p) => _onInsert(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'contacts',
            filter: filter,
            callback: (p) => _onUpdate(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'contacts',
            filter: filter,
            callback: (p) => _onDelete(p.oldRecord),
          )
          .subscribe((status, error) {
            debugPrint('[RT:contacts] $status $error');
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
    if (!ref.read(clientsPageInfoProvider).hasMore) return Future.value(true);
    final future = _fetchNextPage().whenComplete(() => _loadMoreInFlight = null);
    _loadMoreInFlight = future;
    return future;
  }

  Future<bool> _fetchNextPage() async {
    final pageState = ref.read(clientsPageInfoProvider);
    ref.read(clientsPageInfoProvider.notifier).set(
          pageState.copyWith(isLoadingMore: true),
        );
    try {
      final nextPage = pageState.page + 1;
      final result = await _repo.getAll(page: nextPage);
      final existing = state.value ?? [];
      final existingIds = existing.map((c) => c.id).toSet();
      final newItems = result.items.where((c) => !existingIds.contains(c.id));
      state = AsyncData([...existing, ...newItems]);
      ref.read(clientsPageInfoProvider.notifier).set(
            ListPageInfo(page: nextPage, hasMore: result.hasMore),
          );
      return true;
    } catch (_) {
      // Falla de página: se deja `hasMore` como estaba para que el scroll
      // pueda reintentar; quien itera (`loadAll`) se detiene con el `false`.
      ref.read(clientsPageInfoProvider.notifier).set(
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
    while (ref.read(clientsPageInfoProvider).hasMore) {
      final before = ref.read(clientsPageInfoProvider).page;
      final ok = await loadMore();
      if (!ok) return;
      final after = ref.read(clientsPageInfoProvider);
      if (after.hasMore && after.page == before) return;
    }
  }

  /// Pull-to-refresh: vuelve a la página 1 sin pasar por `AsyncLoading`.
  /// Devuelve la clave de error (para `translateError`) o null si salió bien.
  Future<String?> refresh() async {
    try {
      final result = await _repo.getAll(page: 1);
      state = AsyncData(result.items);
      ref.read(clientsPageInfoProvider.notifier).set(
            ListPageInfo(page: 1, hasMore: result.hasMore),
          );
      // Con búsqueda activa el filtro es client-side: hay que volver a bajar
      // el resto, igual que al empezar a buscar.
      if (ref.read(clientSearchProvider).isNotEmpty) unawaited(loadAll());
      return null;
    } catch (e) {
      return mapApiError(e);
    }
  }

  Future<void> _onInsert(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (state.asData?.value.any((c) => c.id == id) == true) return;
    try {
      final contact = await _repo.getById(id);
      state = AsyncData([...state.requireValue, contact]);
    } catch (_) {
      // fire-and-forget: eco de Realtime, se autocorrige con el próximo evento o refetch
    }
  }

  Future<void> _onUpdate(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (row['is_active'] == false) {
      state = AsyncData(state.requireValue.where((c) => c.id != id).toList());
      return;
    }
    try {
      final contact = await _repo.getById(id);
      state = AsyncData([
        for (final c in state.requireValue) if (c.id == id) contact else c,
      ]);
    } catch (_) {
      // fire-and-forget: eco de Realtime, se autocorrige con el próximo evento o refetch
    }
  }

  void _onDelete(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    if (id == null) return;
    state = AsyncData(state.requireValue.where((c) => c.id != id).toList());
  }

  Future<Contact> create({
    required String fullName,
    String? phone,
    String? email,
    String? birthdate,
    String? occupation,
    String? address,
    String? rfc,
    String? curp,
  }) async {
    final created = await _repo.create(
      fullName: fullName,
      phone: phone,
      email: email,
      birthdate: birthdate,
      occupation: occupation,
      address: address,
      rfc: rfc,
      curp: curp,
    );
    if (state.asData?.value.any((c) => c.id == created.id) != true) {
      state = AsyncData([...state.requireValue, created]);
    }
    return created;
  }

  Future<Contact> updateContact(
    String id, {
    required String fullName,
    String? phone,
    String? email,
    String? birthdate,
    String? occupation,
    String? address,
    String? rfc,
    String? curp,
  }) async {
    final updated = await _repo.update(
      id,
      fullName: fullName,
      phone: phone,
      email: email,
      birthdate: birthdate,
      occupation: occupation,
      address: address,
      rfc: rfc,
      curp: curp,
    );
    state = AsyncData([
      for (final c in state.requireValue) if (c.id == id) updated else c,
    ]);
    return updated;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = AsyncData(state.requireValue.where((c) => c.id != id).toList());
  }
}

final clientsProvider =
    AsyncNotifierProvider<ClientsNotifier, List<Contact>>(ClientsNotifier.new);
