import '../models/policy.dart';

abstract class PolicyRepository {
  Future<int> getCount();
  Future<List<Policy>> getByContactId(String contactId);
  Future<({List<Policy> items, bool hasMore})> getAll({
    int page = 1,
    int pageSize = 30,
  });
  Future<Policy> getById(String id);
  Future<Policy> create(Map<String, dynamic> data);
  Future<Policy> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
}
