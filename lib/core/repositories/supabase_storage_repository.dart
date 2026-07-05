import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage_repository.dart';

/// Bucket donde se guardan los documentos subidos (pólizas y conocimiento).
const _kDocumentsBucket = 'policies';

class SupabaseStorageRepository implements StorageRepository {
  SupabaseStorageRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<String> getSignedUrl(String storagePath, {int expiresInSeconds = 3600}) {
    return _client.storage.from(_kDocumentsBucket).createSignedUrl(storagePath, expiresInSeconds);
  }
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return SupabaseStorageRepository(Supabase.instance.client);
});
