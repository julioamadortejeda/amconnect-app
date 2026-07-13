import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/catalog.dart';
import '../network/api_client.dart';
import 'catalog_repository.dart';

class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<Carrier>> getCarriers() async {
    final res = await _client.get('catalog/carriers');
    final items = res['data'] as List<dynamic>;
    return items.map((e) => Carrier.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Carrier> getCarrierById(String id) async {
    final res = await _client.get('catalog/carriers/$id');
    return Carrier.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<Carrier> createCarrier(String name, {String? shortName}) async {
    final res = await _client.post('catalog/carriers', body: {
      'name': name,
      if (shortName != null) 'shortName': shortName,
    });
    return Carrier.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<Carrier> updateCarrier(String id, {required String name, String? shortName}) async {
    final res = await _client.patch('catalog/carriers/$id', body: {
      'name': name,
      'shortName': shortName,
    });
    return Carrier.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCarrier(String id) => _client.delete('catalog/carriers/$id');

  @override
  Future<List<Branch>> getBranches() async {
    final res = await _client.get('catalog/branches');
    final items = res['data'] as List<dynamic>;
    return items.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Branch> getBranchById(String id) async {
    final res = await _client.get('catalog/branches/$id');
    return Branch.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<Branch> createBranch(String name, {String? code}) async {
    final res = await _client.post('catalog/branches', body: {
      'name': name,
      if (code != null) 'code': code,
    });
    return Branch.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<Branch> updateBranch(String id, {required String name, String? code}) async {
    final res = await _client.patch('catalog/branches/$id', body: {
      'name': name,
      'code': code,
    });
    return Branch.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBranch(String id) => _client.delete('catalog/branches/$id');

  @override
  Future<List<Product>> getProducts() async {
    final res = await _client.get('catalog/products');
    final items = res['data'] as List<dynamic>;
    return items.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Product> getProductById(String id) async {
    final res = await _client.get('catalog/products/$id');
    return Product.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<Product> createProduct(String name, String carrierId, String branchId) async {
    final res = await _client.post(
      'catalog/products',
      body: {
        'name': name,
        'carrierId': carrierId,
        'branchId': branchId,
      },
    );
    return Product.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<Product> updateProduct(String id, {required String name, required String carrierId, required String branchId}) async {
    final res = await _client.patch('catalog/products/$id', body: {
      'name': name,
      'carrierId': carrierId,
      'branchId': branchId,
    });
    return Product.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteProduct(String id) => _client.delete('catalog/products/$id');

  @override
  Future<List<PolicyStatus>> getStatuses() async {
    final res = await _client.get('catalog/policy-statuses');
    final items = res['data'] as List<dynamic>;
    return items.map((e) => PolicyStatus.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Currency>> getCurrencies() async {
    final res = await _client.get('catalog/currencies');
    final items = res['data'] as List<dynamic>;
    return items.map((e) => Currency.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<PaymentFrequency>> getPaymentFrequencies() async {
    final res = await _client.get('catalog/payment-frequencies');
    final items = res['data'] as List<dynamic>;
    return items.map((e) => PaymentFrequency.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final res = await _client.get('catalog/payment-methods');
    final items = res['data'] as List<dynamic>;
    return items.map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return SupabaseCatalogRepository(ref.read(apiClientProvider));
});
