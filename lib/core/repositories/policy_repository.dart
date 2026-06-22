import '../models/policy.dart';

abstract class PolicyRepository {
  Future<int> getCount();
  Future<List<Policy>> getByContactId(String contactId);
}
