abstract class StorageRepository {
  /// Genera una URL firmada temporal para abrir un archivo de Storage.
  /// [storagePath] es la ruta dentro del bucket de pólizas/documentos.
  Future<String> getSignedUrl(String storagePath, {int expiresInSeconds});
}
