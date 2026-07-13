import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact.dart';
import '../network/api_client.dart';
import 'contact_repository.dart';

class SupabaseContactRepository implements ContactRepository {
  SupabaseContactRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<Contact>> getAll({String? query}) async {
    final String path;
    if (query != null && query.isNotEmpty) {
      path = 'contacts/search?q=${Uri.encodeQueryComponent(query)}';
    } else {
      path = 'contacts?pageSize=100';
    }
    final res = await _client.get(path);
    final wrapper = res['data'] as Map<String, dynamic>;
    final items = wrapper['data'] as List<dynamic>;
    return items.map((e) => Contact.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Contact> getById(String id) async {
    final res = await _client.get('contacts/$id');
    return Contact.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
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
  }) async {
    final res = await _client.post('contacts', body: {
      'fullName': fullName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (birthdate != null && birthdate.isNotEmpty) 'birthdate': birthdate,
      if (occupation != null && occupation.isNotEmpty) 'occupation': occupation,
      if (address != null && address.isNotEmpty) 'address': address,
      if (rfc != null && rfc.isNotEmpty) 'rfc': rfc,
      if (curp != null && curp.isNotEmpty) 'curp': curp,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Contact.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
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
  }) async {
    final res = await _client.patch('contacts/$id', body: {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'birthdate': birthdate,
      'occupation': occupation,
      'address': address,
      'rfc': rfc,
      'curp': curp,
      'notes': notes,
    });
    return Contact.fromJson(res['data'] as Map<String, dynamic>);
  }
}

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return SupabaseContactRepository(ref.read(apiClientProvider));
});
