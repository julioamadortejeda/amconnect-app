import '../models/catalog.dart';

abstract class CatalogRepository {
  Future<List<Carrier>> getCarriers();
  Future<Carrier> getCarrierById(String id);
  Future<Carrier> createCarrier(String name, {String? shortName});
  Future<Carrier> updateCarrier(String id, {required String name, String? shortName});
  Future<void> deleteCarrier(String id);

  Future<List<Branch>> getBranches();
  Future<Branch> getBranchById(String id);
  Future<Branch> createBranch(String name, {String? code});
  Future<Branch> updateBranch(String id, {required String name, String? code});
  Future<void> deleteBranch(String id);

  Future<List<Product>> getProducts();
  Future<Product> getProductById(String id);
  Future<Product> createProduct(String name, String carrierId, String branchId);
  Future<Product> updateProduct(String id, {required String name, required String carrierId, required String branchId});
  Future<void> deleteProduct(String id);

  Future<List<PolicyStatus>> getStatuses();
  Future<List<Currency>> getCurrencies();
  Future<List<PaymentFrequency>> getPaymentFrequencies();
  Future<List<PaymentMethod>> getPaymentMethods();
}
