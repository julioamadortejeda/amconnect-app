/// Contrato de respuesta del backend: `{ success, data }`, y para listados
/// `data` es una página `{ data, total?, page, pageSize, hasMore }`. Todo
/// repositorio lee las respuestas por aquí, no con casts sueltos.
library;

/// El `data` de un sobre `{ success, data }` cuando es un objeto.
Map<String, dynamic> unwrapData(Map<String, dynamic> res) =>
    res['data'] as Map<String, dynamic>;

/// Una página del listado paginado del backend.
class PageResponse<T> {
  const PageResponse({required this.items, required this.hasMore, this.total});

  final List<T> items;
  final bool hasMore;

  /// Ausente en las búsquedas que el backend no puede contar.
  final int? total;

  factory PageResponse.fromEnvelope(
    Map<String, dynamic> res,
    T Function(Map<String, dynamic>) parse,
  ) {
    final page = unwrapData(res);
    final rows = page['data'] as List<dynamic>? ?? const [];
    return PageResponse(
      items: rows.map((e) => parse(e as Map<String, dynamic>)).toList(),
      hasMore: page['hasMore'] as bool? ?? false,
      total: (page['total'] as num?)?.toInt(),
    );
  }
}

/// Tamaño de página máximo que acepta el backend (`shared/pagination.ts`).
const kMaxPageSize = 100;

/// Recorre todas las páginas de un listado.
///
/// Para pantallas que necesitan la lista completa (calendario, agenda, todas
/// las notas de un cliente): el backend ya no devuelve "todo" de golpe, así que
/// se itera aquí en vez de truncar en silencio. [fetch] pide la página
/// `page` de tamaño `pageSize` y devuelve el sobre crudo. [idOf] quita
/// duplicados: algo creado entre página y página recorre el orden y repetiría
/// una fila ya leída.
///
/// [maxPages] es un freno de seguridad (50 páginas de 100 = 5,000 filas) por si
/// el backend respondiera `hasMore: true` para siempre.
Future<List<T>> fetchAllPages<T>({
  required Future<Map<String, dynamic>> Function(int page, int pageSize) fetch,
  required T Function(Map<String, dynamic>) parse,
  String Function(T item)? idOf,
  int pageSize = kMaxPageSize,
  int maxPages = 50,
}) async {
  final all = <T>[];
  final seen = <String>{};
  for (var page = 1; page <= maxPages; page++) {
    final res = PageResponse.fromEnvelope(await fetch(page, pageSize), parse);
    for (final item in res.items) {
      if (idOf == null || seen.add(idOf(item))) all.add(item);
    }
    if (!res.hasMore || res.items.isEmpty) break;
  }
  return all;
}
