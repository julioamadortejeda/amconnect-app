import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/catalog.dart';
import '../../../core/network/api_client.dart';
import '../../clients/providers/catalog_provider.dart';

enum CatalogType { carriers, branches, products }

// ─── UI: tipo activo + búsqueda ────────────────────────────────────────────

class CatalogsUiNotifier extends Notifier<CatalogType> {
  @override
  CatalogType build() => CatalogType.carriers;

  void select(CatalogType type) {
    state = type;
    ref.read(catalogSearchProvider.notifier).set('');
  }
}

final catalogsUiProvider =
    NotifierProvider<CatalogsUiNotifier, CatalogType>(CatalogsUiNotifier.new);

class CatalogSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final catalogSearchProvider =
    NotifierProvider<CatalogSearchNotifier, String>(CatalogSearchNotifier.new);

// ─── Formularios: crear/editar ──────────────────────────────────────────────

class CatalogFormState {
  const CatalogFormState({this.loading = false, this.error});

  final bool loading;

  /// errorCode o mensaje crudo del backend — se traduce con
  /// `context.translateError` en la pantalla.
  final String? error;

  CatalogFormState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
  }) => CatalogFormState(
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );
}

class CreateCarrierNotifier extends Notifier<CatalogFormState> {
  @override
  CatalogFormState build() => const CatalogFormState();

  Future<Carrier?> submit({required String name, String? shortName}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final created = await ref
          .read(carriersProvider.notifier)
          .createCarrier(name, shortName: shortName);
      state = state.copyWith(loading: false);
      return created;
    } on ApiException catch (e) {
      state = CatalogFormState(error: e.errorCode ?? e.message);
      return null;
    }
  }

  Future<Carrier?> update(String id, {required String name, String? shortName}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final updated = await ref
          .read(carriersProvider.notifier)
          .updateCarrier(id, name: name, shortName: shortName);
      state = state.copyWith(loading: false);
      return updated;
    } on ApiException catch (e) {
      state = CatalogFormState(error: e.errorCode ?? e.message);
      return null;
    }
  }

  Future<bool> delete(String id) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await ref.read(carriersProvider.notifier).deleteCarrier(id);
      state = state.copyWith(loading: false);
      return true;
    } on ApiException catch (e) {
      state = CatalogFormState(error: e.errorCode ?? e.message);
      return false;
    }
  }

  void reset() => state = const CatalogFormState();
}

final createCarrierProvider =
    NotifierProvider<CreateCarrierNotifier, CatalogFormState>(CreateCarrierNotifier.new);

class CreateBranchNotifier extends Notifier<CatalogFormState> {
  @override
  CatalogFormState build() => const CatalogFormState();

  Future<Branch?> submit({required String name, String? code}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final created = await ref
          .read(branchesProvider.notifier)
          .createBranch(name, code: code);
      state = state.copyWith(loading: false);
      return created;
    } on ApiException catch (e) {
      state = CatalogFormState(error: e.errorCode ?? e.message);
      return null;
    }
  }

  Future<Branch?> update(String id, {required String name, String? code}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final updated = await ref
          .read(branchesProvider.notifier)
          .updateBranch(id, name: name, code: code);
      state = state.copyWith(loading: false);
      return updated;
    } on ApiException catch (e) {
      state = CatalogFormState(error: e.errorCode ?? e.message);
      return null;
    }
  }

  Future<bool> delete(String id) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await ref.read(branchesProvider.notifier).deleteBranch(id);
      state = state.copyWith(loading: false);
      return true;
    } on ApiException catch (e) {
      state = CatalogFormState(error: e.errorCode ?? e.message);
      return false;
    }
  }

  void reset() => state = const CatalogFormState();
}

final createBranchProvider =
    NotifierProvider<CreateBranchNotifier, CatalogFormState>(CreateBranchNotifier.new);

class CreateProductNotifier extends Notifier<CatalogFormState> {
  @override
  CatalogFormState build() => const CatalogFormState();

  Future<Product?> submit({
    required String name,
    required String carrierId,
    required String branchId,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final created = await ref
          .read(productsProvider.notifier)
          .createProduct(name, carrierId, branchId);
      state = state.copyWith(loading: false);
      return created;
    } on ApiException catch (e) {
      state = CatalogFormState(error: e.errorCode ?? e.message);
      return null;
    }
  }

  Future<Product?> update(
    String id, {
    required String name,
    required String carrierId,
    required String branchId,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final updated = await ref.read(productsProvider.notifier).updateProduct(
            id,
            name: name,
            carrierId: carrierId,
            branchId: branchId,
          );
      state = state.copyWith(loading: false);
      return updated;
    } on ApiException catch (e) {
      state = CatalogFormState(error: e.errorCode ?? e.message);
      return null;
    }
  }

  Future<bool> delete(String id) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await ref.read(productsProvider.notifier).deleteProduct(id);
      state = state.copyWith(loading: false);
      return true;
    } on ApiException catch (e) {
      state = CatalogFormState(error: e.errorCode ?? e.message);
      return false;
    }
  }

  void reset() => state = const CatalogFormState();
}

final createProductProvider =
    NotifierProvider<CreateProductNotifier, CatalogFormState>(CreateProductNotifier.new);
