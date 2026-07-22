import '../models/contact.dart';

abstract class ContactRepository {
  Future<int> getCount();
  Future<({List<Contact> items, bool hasMore})> getAll({
    int page = 1,
    int pageSize = 30,
  });
  Future<Contact> getById(String id);
  Future<Contact> create({
    required String fullName,
    String? phone,
    String? email,
    String? birthdate,
    String? occupation,
    String? address,
    String? rfc,
    String? curp,
  });
  Future<Contact> update(
    String id, {
    required String fullName,
    String? phone,
    String? email,
    String? birthdate,
    String? occupation,
    String? address,
    String? rfc,
    String? curp,
  });
  Future<void> delete(String id);
}
