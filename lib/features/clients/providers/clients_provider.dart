import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/models/contact.dart';
import 'package:amconnect/core/repositories/contact_repository.dart';
import 'package:amconnect/core/repositories/supabase_contact_repository.dart';

class ClientsNotifier extends AsyncNotifier<List<Contact>> {
  late final ContactRepository _repo;

  @override
  Future<List<Contact>> build() async {
    _repo = ref.read(contactRepositoryProvider);
    return _repo.getAll();
  }
}

final clientsProvider =
    AsyncNotifierProvider<ClientsNotifier, List<Contact>>(ClientsNotifier.new);

final contactDetailProvider =
    FutureProvider.family<Contact, String>((ref, id) async {
  return ref.read(contactRepositoryProvider).getById(id);
});
