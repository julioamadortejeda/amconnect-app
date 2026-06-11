import 'package:amconnect/core/models/contact.dart';

abstract class ContactRepository {
  Future<List<Contact>> getAll({String? query});
  Future<Contact> getById(String id);
}
