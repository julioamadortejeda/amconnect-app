import 'package:flutter/material.dart';
import '../utils/error_translator.dart';

/// Pull-to-refresh estándar de las listas principales.
///
/// [onRefresh] es el `refresh()` del notifier: recarga sin pasar por
/// `AsyncLoading` (lo que el asesor ve se queda en pantalla) y devuelve la
/// clave de error ya mapeada, o null si salió bien. Si falla, se avisa con un
/// SnackBar traducido en vez de cambiar la lista por un error.
///
/// El [child] scrollable debe usar `AlwaysScrollableScrollPhysics` para que
/// el gesto funcione aunque la lista sea más corta que la pantalla.
class AmRefresh extends StatelessWidget {
  const AmRefresh({super.key, required this.onRefresh, required this.child});

  final Future<String?> Function() onRefresh;
  final Widget child;

  Future<void> _handle(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final error = await onRefresh();
    if (error == null || !context.mounted) return;
    messenger?.showSnackBar(SnackBar(
      content: Text(context.translateError(error)),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _handle(context),
      child: child,
    );
  }
}
