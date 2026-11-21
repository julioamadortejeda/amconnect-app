/// Código de un catálogo global (estado de póliza, frecuencia, método de
/// pago) para traducirlo con `CatalogL10n`.
///
/// Usa `code` cuando viene. Si no (backend anterior, que solo mandaba
/// `{id, name}` en las relaciones de la póliza), lo deriva del `name`:
/// "Direct Debit" → `DIRECT_DEBIT`. Antes se hacía `name.toUpperCase()` y los
/// nombres de dos palabras quedaban como `DIRECT DEBIT`, que no existe en el
/// mapa de traducciones, así que se mostraba el inglés crudo.
String catalogCode(String? code, String? name) {
  final c = code?.trim() ?? '';
  if (c.isNotEmpty) return c.toUpperCase();
  final n = name?.trim() ?? '';
  return n.toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');
}
