import '../models/contact.dart';

abstract class ContactRepository {
  Future<List<Contact>> getAll({String? query});
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
    String? notes,
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
    String? notes,
  });
}
