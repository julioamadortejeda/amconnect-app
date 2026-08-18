import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ruta que quedó pendiente de abrir porque la app arrancó en frío.
///
/// Cuando se toca una notificación con la app cerrada no se puede navegar de
/// inmediato: el splash termina su precarga y hace `context.go('/home')`, y `go`
/// **reemplaza toda la pila** — cualquier detalle empujado antes desaparece. Eso
/// se veía como que el recordatorio se abría y un instante después saltaba al
/// dashboard.
///
/// La ruta se guarda aquí y el splash la consume DESPUÉS de su propio `go`.
/// Con la app en segundo plano no interviene: ahí el splash no corre y el push
/// directo funciona.
class PendingRouteNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void store(String route) => state = route;

  /// Devuelve la ruta pendiente y la limpia, para que no se vuelva a abrir en
  /// el siguiente arranque.
  String? take() {
    final route = state;
    state = null;
    return route;
  }
}

final pendingRouteProvider =
    NotifierProvider<PendingRouteNotifier, String?>(PendingRouteNotifier.new);
