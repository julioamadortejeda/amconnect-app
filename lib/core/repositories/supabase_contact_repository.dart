import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact.dart';
import '../network/api_client.dart';
import 'contact_repository.dart';

class SupabaseContactRepository implements ContactRepository {
  SupabaseContactRepository(this._client);
  final ApiClient _client;

  @override
  Future<int> getCount() async {
    final res = await _client.get('contacts?pageSize=1');
    final wrapper = res['data'] as Map<String, dynamic>;
    return wrapper['total'] as int? ?? (wrapper['data'] as List?)?.length ?? 0;
  }

  @override
  Future<({List<Contact> items, bool hasMore})> getAll({
    int page = 1,
    int pageSize = 30,
  }) async {
    final res = await _client.get('contacts?page=$page&pageSize=$pageSize');
    final wrapper = res['data'] as Map<String, dynamic>;
    final items = wrapper['data'] as List<dynamic>;
    return (
      items: items.map((e) => Contact.fromJson(e as Map<String, dynamic>)).toList(),
      hasMore: wrapper['hasMore'] as bool? ?? false,
    );
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

  @override
  Future<void> delete(String id) async {
    await _client.delete('contacts/$id');
  }
}

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return SupabaseContactRepository(ref.read(apiClientProvider));
});
