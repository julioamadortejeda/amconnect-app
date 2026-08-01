import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/error_translator.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/ingest_provider.dart';

/// Se muestra cuando el titular detectado por la IA en el documento no
/// coincide con el cliente de la pantalla desde donde se disparó la ingesta
/// (ver `PolicyIngestionService.extract` en el backend). El asesor decide si
/// asignar la póliza al cliente de la pantalla de todos modos, o seguir el
/// flujo normal con el contacto detectado.
class ContactMismatchSheet extends ConsumerWidget {
  const ContactMismatchSheet({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(ingestProvider);
    final mismatch = state.contactMismatch;

    final screenName = mismatch?.screenContactName ?? '';
    final detectedName = mismatch?.detectedContactName ?? '';

    return Container(
      color: AmColors.scrim,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AmDimens.cardRadius)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: AmDimens.gapM),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: am.amberWash,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: am.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 18, color: am.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.feedContactMismatchBody(detectedName, screenName),
                        style: TextStyle(fontSize: 13, color: cs.onSurface, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AmDimens.gapM),
              Text(
                l10n.feedContactMismatchTitle,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
              ),
              const SizedBox(height: AmDimens.gapM),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AmColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: state.isSending
                      ? null
                      : () => ref.read(ingestProvider.notifier).resolveContactMismatch(true),
                  child: state.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          l10n.feedContactMismatchAssignCta(screenName),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: AmDimens.gapS),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.onSurface,
                    side: BorderSide(color: cs.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: state.isSending
                      ? null
                      : () => ref.read(ingestProvider.notifier).resolveContactMismatch(false),
                  child: Text(
                    l10n.feedContactMismatchUseDetectedCta(detectedName),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: AmDimens.gapXS),
                Text(
                  context.translateError(state.error!),
                  style: TextStyle(fontSize: 12.5, color: cs.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
