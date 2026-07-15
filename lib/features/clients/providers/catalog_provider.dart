import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/catalog.dart';
import '../../../core/repositories/catalog_repository.dart';
import '../../../core/repositories/supabase_catalog_repository.dart';

// ─── Custom Catalogs (Mutable) ────────────────────────────────────────────────

class CarriersNotifier extends AsyncNotifier<List<Carrier>> {
  late CatalogRepository _repo;
  RealtimeChannel? _channel;

  @override
  Future<List<Carrier>> build() async {
    _repo = ref.read(catalogRepositoryProvider);
    final initial = await _repo.getCarriers();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'agent_id',
        value: userId,
      );
      _channel = Supabase.instance.client
          .channel('carriers:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'carriers',
            filter: filter,
            callback: (p) => _onInsert(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'carriers',
            filter: filter,
            callback: (p) => _onUpdate(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'carriers',
            filter: filter,
            callback: (p) => _onDelete(p.oldRecord),
          )
          .subscribe((status, error) {
            debugPrint('[RT:carriers] $status $error');
          });

      ref.onDispose(() { _channel?.unsubscribe(); });
    }

    return initial;
  }

  Future<void> _onInsert(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (state.asData?.value.any((c) => c.id == id) == true) return;
    try {
      final carrier = await _repo.getCarrierById(id);
      state = AsyncData([...state.requireValue, carrier]);
    } catch (_) {}
  }

  Future<void> _onUpdate(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (row['is_active'] == false) {
      state = AsyncData(state.requireValue.where((c) => c.id != id).toList());
      return;
    }
    try {
      final carrier = await _repo.getCarrierById(id);
      state = AsyncData([
        for (final c in state.requireValue) if (c.id == id) carrier else c,
      ]);
    } catch (_) {}
  }

  void _onDelete(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    if (id == null) return;
    state = AsyncData(state.requireValue.where((c) => c.id != id).toList());
  }

  Future<Carrier> createCarrier(String name, {String? shortName}) async {
    final newCarrier = await _repo.createCarrier(name, shortName: shortName);
    if (state.asData?.value.any((c) => c.id == newCarrier.id) != true) {
      state = AsyncData([...state.requireValue, newCarrier]);
    }
    return newCarrier;
  }

  Future<Carrier> updateCarrier(String id, {required String name, String? shortName}) async {
    final updated = await _repo.updateCarrier(id, name: name, shortName: shortName);
    state = AsyncData([
      for (final c in state.requireValue) if (c.id == id) updated else c,
    ]);
    return updated;
  }

  Future<void> deleteCarrier(String id) async {
    await _repo.deleteCarrier(id);
    state = AsyncData(state.requireValue.where((c) => c.id != id).toList());
  }
}

final carriersProvider =
    AsyncNotifierProvider<CarriersNotifier, List<Carrier>>(CarriersNotifier.new);

class BranchesNotifier extends AsyncNotifier<List<Branch>> {
  late CatalogRepository _repo;
  RealtimeChannel? _channel;

  @override
  Future<List<Branch>> build() async {
    _repo = ref.read(catalogRepositoryProvider);
    final initial = await _repo.getBranches();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'agent_id',
        value: userId,
      );
      _channel = Supabase.instance.client
          .channel('branches:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'branches',
            filter: filter,
            callback: (p) => _onInsert(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'branches',
            filter: filter,
            callback: (p) => _onUpdate(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'branches',
            filter: filter,
            callback: (p) => _onDelete(p.oldRecord),
          )
          .subscribe((status, error) {
            debugPrint('[RT:branches] $status $error');
          });

      ref.onDispose(() { _channel?.unsubscribe(); });
    }

    return initial;
  }

  Future<void> _onInsert(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (state.asData?.value.any((b) => b.id == id) == true) return;
    try {
      final branch = await _repo.getBranchById(id);
      state = AsyncData([...state.requireValue, branch]);
    } catch (_) {}
  }

  Future<void> _onUpdate(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (row['is_active'] == false) {
      state = AsyncData(state.requireValue.where((b) => b.id != id).toList());
      return;
    }
    try {
      final branch = await _repo.getBranchById(id);
      state = AsyncData([
        for (final b in state.requireValue) if (b.id == id) branch else b,
      ]);
    } catch (_) {}
  }

  void _onDelete(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    if (id == null) return;
    state = AsyncData(state.requireValue.where((b) => b.id != id).toList());
  }

  Future<Branch> createBranch(String name, {String? code}) async {
    final newBranch = await _repo.createBranch(name, code: code);
    if (state.asData?.value.any((b) => b.id == newBranch.id) != true) {
      state = AsyncData([...state.requireValue, newBranch]);
    }
    return newBranch;
  }

  Future<Branch> updateBranch(String id, {required String name, String? code}) async {
    final updated = await _repo.updateBranch(id, name: name, code: code);
    state = AsyncData([
      for (final b in state.requireValue) if (b.id == id) updated else b,
    ]);
    return updated;
  }

  Future<void> deleteBranch(String id) async {
    await _repo.deleteBranch(id);
    state = AsyncData(state.requireValue.where((b) => b.id != id).toList());
  }
}

final branchesProvider =
    AsyncNotifierProvider<BranchesNotifier, List<Branch>>(BranchesNotifier.new);

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  late CatalogRepository _repo;
  RealtimeChannel? _channel;

  @override
  Future<List<Product>> build() async {
    _repo = ref.read(catalogRepositoryProvider);
    final initial = await _repo.getProducts();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'agent_id',
        value: userId,
      );
      _channel = Supabase.instance.client
          .channel('products:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'products',
            filter: filter,
            callback: (p) => _onInsert(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'products',
            filter: filter,
            callback: (p) => _onUpdate(p.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'products',
            filter: filter,
            callback: (p) => _onDelete(p.oldRecord),
          )
          .subscribe((status, error) {
            debugPrint('[RT:products] $status $error');
          });

      ref.onDispose(() { _channel?.unsubscribe(); });
    }

    return initial;
  }

  Future<void> _onInsert(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (state.asData?.value.any((p) => p.id == id) == true) return;
    try {
      final product = await _repo.getProductById(id);
      state = AsyncData([...state.requireValue, product]);
    } catch (_) {}
  }

  Future<void> _onUpdate(Map<String, dynamic> row) async {
    final id = row['id'] as String?;
    if (id == null) return;
    if (row['is_active'] == false) {
      state = AsyncData(state.requireValue.where((p) => p.id != id).toList());
      return;
    }
    try {
      final product = await _repo.getProductById(id);
      state = AsyncData([
        for (final p in state.requireValue) if (p.id == id) product else p,
      ]);
    } catch (_) {}
  }

  void _onDelete(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    if (id == null) return;
    state = AsyncData(state.requireValue.where((p) => p.id != id).toList());
  }

  Future<Product> createProduct(String name, String carrierId, String branchId) async {
    final newProduct = await _repo.createProduct(name, carrierId, branchId);
    if (state.asData?.value.any((p) => p.id == newProduct.id) != true) {
      state = AsyncData([...state.requireValue, newProduct]);
    }
    return newProduct;
  }

  Future<Product> updateProduct(String id, {required String name, required String carrierId, required String branchId}) async {
    final updated = await _repo.updateProduct(id, name: name, carrierId: carrierId, branchId: branchId);
    state = AsyncData([
      for (final p in state.requireValue) if (p.id == id) updated else p,
    ]);
    return updated;
  }

  Future<void> deleteProduct(String id) async {
    await _repo.deleteProduct(id);
    state = AsyncData(state.requireValue.where((p) => p.id != id).toList());
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);

// ─── Global Catalogs (Read-Only) ────────────────────────────────────────────────

final statusesProvider = FutureProvider<List<PolicyStatus>>((ref) {
  return ref.read(catalogRepositoryProvider).getStatuses();
});

final currenciesProvider = FutureProvider<List<Currency>>((ref) {
  return ref.read(catalogRepositoryProvider).getCurrencies();
});

final frequenciesProvider = FutureProvider<List<PaymentFrequency>>((ref) {
  return ref.read(catalogRepositoryProvider).getPaymentFrequencies();
});

final methodsProvider = FutureProvider<List<PaymentMethod>>((ref) {
  return ref.read(catalogRepositoryProvider).getPaymentMethods();
});
