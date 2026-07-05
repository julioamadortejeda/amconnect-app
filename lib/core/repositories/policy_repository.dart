import '../models/policy.dart';

abstract class PolicyRepository {
  Future<int> getCount();
  Future<List<Policy>> getByContactId(String contactId);
  Future<List<Policy>> getAll();
  Future<Policy> getById(String id);
}
