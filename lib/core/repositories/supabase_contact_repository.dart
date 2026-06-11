import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/models/contact.dart';
import 'package:amconnect/core/network/api_client.dart';
import 'package:amconnect/core/repositories/contact_repository.dart';

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
}

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return SupabaseContactRepository(ref.read(apiClientProvider));
});
