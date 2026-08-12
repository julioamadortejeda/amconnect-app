import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/agent_note.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/policy.dart';
import '../../../core/models/reminder.dart';
import '../../../core/network/api_client.dart';
import '../../../core/repositories/contact_repository.dart';
import '../../../core/repositories/supabase_contact_repository.dart';
import '../../../core/repositories/supabase_note_repository.dart';
import '../../../core/repositories/supabase_reminder_repository.dart';
import '../../../core/repositories/policy_repository.dart';
import '../../../core/repositories/supabase_policy_repository.dart';
import '../../../core/models/ai_chat_context.dart';
import '../../home/providers/home_provider.dart';

class _SearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final clientSearchProvider =
    NotifierProvider<_SearchNotifier, String>(_SearchNotifier.new);

class _PolicySearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final policySearchProvider =
    NotifierProvider<_PolicySearchNotifier, String>(_PolicySearchNotifier.new);

/// Estado de paginación de una lista con scroll infinito — separado del
/// `state` del AsyncNotifier (que sigue siendo `List<T>` puro, sin romper
/// a los ~10 lugares que ya consumen `clientsProvider`/`policiesProvider`).
class ListPageInfo {
  const ListPageInfo({
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  ListPageInfo copyWith({int? page, bool? hasMore, bool? isLoadingMore}) =>
      ListPageInfo(
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class _ClientsPageNotifier extends Notifier<ListPageInfo> {
  @override
  ListPageInfo build() => const ListPageInfo();
  void set(ListPageInfo v) => state = v;
}

final clientsPageInfoProvider =
    NotifierProvider<_ClientsPageNotifier, ListPageInfo>(_ClientsPageNotifier.new);

class _PoliciesPageNotifier extends Notifier<ListPageInfo> {
  @override
  ListPageInfo build() => const ListPageInfo();
  void set(ListPageInfo v) => state = v;
}

final policiesPageInfoProvider =
    NotifierProvider<_PoliciesPageNotifier, ListPageInfo>(_PoliciesPageNotifier.new);

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

  /// Carga la siguiente página y la añade a la lista ya cargada.
  Future<void> loadMore() async {
    final pageState = ref.read(clientsPageInfoProvider);
    if (pageState.isLoadingMore || !pageState.hasMore) return;
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
    } catch (_) {
      ref.read(clientsPageInfoProvider.notifier).set(
            pageState.copyWith(isLoadingMore: false),
          );
    }
  }

  /// Carga todas las páginas restantes de una sola vez — usado cuando hay
  /// una búsqueda activa (ver `build`).
  Future<void> loadAll() async {
    while (ref.read(clientsPageInfoProvider).hasMore) {
      await loadMore();
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

/// Estado del formulario de creación manual de clientes.
class CreateClientState {
  const CreateClientState({this.loading = false, this.error});

  final bool loading;

  /// errorCode o mensaje crudo del backend — se traduce con
  /// `context.translateError` en la pantalla.
  final String? error;

  CreateClientState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
  }) => CreateClientState(
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );
}

class CreateClientNotifier extends Notifier<CreateClientState> {
  @override
  CreateClientState build() => const CreateClientState();

  Future<Contact?> submit({
    required String fullName,
    String? phone,
    String? email,
    String? birthdate,
    String? occupation,
    String? address,
    String? rfc,
    String? curp,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final created = await ref.read(clientsProvider.notifier).create(
        fullName: fullName,
        phone: phone,
        email: email,
        birthdate: birthdate,
        occupation: occupation,
        address: address,
        rfc: rfc,
        curp: curp,
      );
      state = state.copyWith(loading: false);
      return created;
    } on ApiException catch (e) {
      state = CreateClientState(error: e.errorCode ?? e.message);
      return null;
    }
  }

  Future<Contact?> updateContact(
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
    state = state.copyWith(loading: true, clearError: true);
    try {
      final updated = await ref.read(clientsProvider.notifier).updateContact(
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
      state = state.copyWith(loading: false);
      return updated;
    } on ApiException catch (e) {
      state = CreateClientState(error: e.errorCode ?? e.message);
      return null;
    }
  }

  void reset() => state = const CreateClientState();
}

final createClientProvider =
    NotifierProvider<CreateClientNotifier, CreateClientState>(
        CreateClientNotifier.new);

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

  /// Carga la siguiente página y la añade a la lista ya cargada.
  Future<void> loadMore() async {
    final pageState = ref.read(policiesPageInfoProvider);
    if (pageState.isLoadingMore || !pageState.hasMore) return;
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
    } catch (_) {
      ref.read(policiesPageInfoProvider.notifier).set(
            pageState.copyWith(isLoadingMore: false),
          );
    }
  }

  /// Carga todas las páginas restantes de una sola vez — usado cuando hay
  /// una búsqueda activa (ver `build`).
  Future<void> loadAll() async {
    while (ref.read(policiesPageInfoProvider).hasMore) {
      await loadMore();
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

/// Fuerza la carga de todas las páginas de clientes y pólizas — para
/// pantallas que necesitan la cartera completa (selectores, analytics),
/// no solo lo que ya esté cargado por scroll. `autoDispose` para que se
/// vuelva a evaluar cada vez que la pantalla que lo usa se vuelve a montar.
final ensureFullPortfolioDataProvider = FutureProvider.autoDispose<void>((ref) async {
  await Future.wait([
    ref.read(clientsProvider.notifier).loadAll(),
    ref.read(policiesProvider.notifier).loadAll(),
  ]);
});

/// Agrupa recordatorios activos por contactId — sin red, derivado de remindersProvider.
final contactRemindersMapProvider = Provider<Map<String, List<Reminder>>>((ref) {
  final reminders = ref.watch(remindersProvider).asData?.value ?? [];
  final map = <String, List<Reminder>>{};
  for (final r in reminders) {
    if (!r.isActive) continue;
    final cid = r.contactId;
    if (cid == null) continue;
    (map[cid] ??= []).add(r);
  }
  return map;
});

final contactDetailProvider =
    FutureProvider.family<Contact, String>((ref, id) async {
  return ref.read(contactRepositoryProvider).getById(id);
});

final contactPoliciesProvider =
    FutureProvider.family<List<Policy>, String>((ref, contactId) async {
  return ref.read(policyRepositoryProvider).getByContactId(contactId);
});

// Watching this provider activates Realtime for policies of a contact.
// autoDispose ensures the channel closes when the screen is popped.
final contactPoliciesRealtimeProvider =
    Provider.autoDispose.family<void, String>((ref, contactId) {
  final channel = Supabase.instance.client
      .channel('policies:contact:$contactId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'policies',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'contact_id',
          value: contactId,
        ),
        callback: (_) => ref.invalidate(contactPoliciesProvider(contactId)),
      )
      .subscribe();
  ref.onDispose(() => channel.unsubscribe());
});

final contactNotesProvider =
    FutureProvider.family<List<AgentNote>, String>((ref, contactId) async {
  return ref.read(noteRepositoryProvider).getByContactId(contactId);
});

final policyNotesProvider =
    FutureProvider.family<List<AgentNote>, String>((ref, policyId) async {
  return ref.read(noteRepositoryProvider).getByPolicyId(policyId);
});

/// Recordatorios de una póliza — incluye los cerrados, porque es el historial
/// de pagos y renovaciones que se muestra en su detalle.
final policyRemindersProvider =
    FutureProvider.family<List<Reminder>, String>((ref, policyId) async {
  return ref.read(reminderRepositoryProvider).getByPolicy(policyId);
});

/// Observar este provider mantiene al día la actividad de una póliza.
final policyRemindersRealtimeProvider =
    Provider.autoDispose.family<void, String>((ref, policyId) {
  final channel = Supabase.instance.client
      .channel('reminders:policy:$policyId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'reminders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'policy_id',
          value: policyId,
        ),
        callback: (_) => ref.invalidate(policyRemindersProvider(policyId)),
      )
      .subscribe();
  ref.onDispose(() => channel.unsubscribe());
});

// Watching this provider activates Realtime for notes of a contact.
final contactNotesRealtimeProvider =
    Provider.autoDispose.family<void, String>((ref, contactId) {
  final channel = Supabase.instance.client
      .channel('notes:contact:$contactId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'agent_notes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'contact_id',
          value: contactId,
        ),
        callback: (_) => ref.invalidate(contactNotesProvider(contactId)),
      )
      .subscribe();
  ref.onDispose(() => channel.unsubscribe());
});

// Watching this provider activates Realtime for notes of a policy — necesario
// porque la ingesta de archivo/texto con IA es asíncrona (tarda segundos) y
// nada más refresca policyNotesProvider cuando termina.
final policyNotesRealtimeProvider =
    Provider.autoDispose.family<void, String>((ref, policyId) {
  final channel = Supabase.instance.client
      .channel('notes:policy:$policyId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'agent_notes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'policy_id',
          value: policyId,
        ),
        callback: (_) => ref.invalidate(policyNotesProvider(policyId)),
      )
      .subscribe();
  ref.onDispose(() => channel.unsubscribe());
});

/// Contexto de IA listo para enviar al chat, construido con los datos
/// ya cargados en pantalla (contacto + pólizas + notas).
final contactAiContextProvider =
    Provider.family<AiChatContext, String>((ref, contactId) {
  final contact = ref.watch(clientsProvider).asData?.value
          .where((c) => c.id == contactId)
          .firstOrNull ??
      ref.watch(contactDetailProvider(contactId)).asData?.value;

  if (contact == null) {
    return AiChatContext(type: 'contact', id: contactId, data: {});
  }

  final policies = ref.watch(contactPoliciesProvider(contactId)).asData?.value;
  final contactNotes = ref.watch(contactNotesProvider(contactId)).asData?.value ?? [];

  // El asesor espera que el chat "sepa" todo sobre el cliente, incluidas las
  // notas que se agregaron desde el detalle de una póliza suya (note_origin
  // 'policy') — no solo las de conocimiento general (note_origin 'knowledge').
  final policyNotes = <AgentNote>[
    for (final p in policies ?? <Policy>[])
      ...(ref.watch(policyNotesProvider(p.id)).asData?.value ?? <AgentNote>[]),
  ];

  return AiChatContext.fromContact(
    contact,
    policies: policies,
    notes: [...contactNotes, ...policyNotes],
  );
});

