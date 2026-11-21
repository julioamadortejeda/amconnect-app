import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';
import '../../l10n/app_localizations.dart';

/// Estado de error de una pantalla o lista con botón de reintentar.
///
/// [message] ya debe venir traducido (`context.translateError(...)` o una
/// clave l10n). Existe para que ningún fallo de red se quede en un loader
/// infinito: siempre hay una salida que el asesor puede tocar.
class AmErrorRetry extends StatelessWidget {
  const AmErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
    this.detail,
  });

  final String message;

  /// Texto secundario opcional (p. ej. el error traducido debajo del título).
  final String? detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: cs.tertiary),
            const SizedBox(height: AmDimens.gapS),
            Text(
              message,
              textAlign: TextAlign.center,
              style: tt.bodyLarge?.copyWith(color: cs.onSurface),
            ),
            if (detail != null && detail!.isNotEmpty && detail != message) ...[
              const SizedBox(height: AmDimens.gapXS),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.tertiary),
              ),
            ],
            const SizedBox(height: AmDimens.gapM),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
