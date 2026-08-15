import 'package:flutter/material.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/share_target_provider.dart';

/// Explica qué va a pasar con el contenido según el destino elegido: alta
/// automática de póliza (con todo lo que el flujo genera solo) o nota.
class ShareDestinationNotice extends StatelessWidget {
  const ShareDestinationNotice({super.key, required this.state});

  final ShareTargetState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPolicyIngest = state.destinationType == ShareDestinationType.policyIngest;

    // El tipo de archivo bloquea cualquier destino que no sea alta de póliza
    // (esa ya se auto-deshabilita con su propio aviso en el selector) — se
    // muestra encima de cualquier otro mensaje.
    if (!isPolicyIngest && state.isUnsupportedFile) {
      return Container(
        padding: const EdgeInsets.all(AmDimens.gapM),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 18, color: cs.error),
            const SizedBox(width: AmDimens.gapS),
            Expanded(
              child: Text(
                l10n.shareTargetUnsupportedFile,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.error, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final message = switch (state.destinationType) {
      ShareDestinationType.policyIngest => l10n.shareTargetNoticePolicyIngest,
      ShareDestinationType.global => l10n.shareTargetNoticeGlobal,
      ShareDestinationType.client => state.selectedClientName == null
          ? l10n.shareTargetNoticePickClient
          : l10n.shareTargetNoticeClient(state.selectedClientName!),
      ShareDestinationType.policy => state.selectedPolicyNumber == null
          ? l10n.shareTargetNoticePickPolicy
          : l10n.shareTargetNoticePolicy(state.selectedPolicyNumber!),
      ShareDestinationType.reminder => state.selectedReminderTitle == null
          ? l10n.shareTargetNoticePickReminder
          : l10n.shareTargetNoticeReminder(state.selectedReminderTitle!),
    };

    return Container(
      padding: const EdgeInsets.all(AmDimens.gapM),
      decoration: BoxDecoration(
        color: isPolicyIngest ? cs.primaryContainer : cs.secondaryContainer,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPolicyIngest ? Icons.auto_awesome : Icons.sticky_note_2_outlined,
            size: 18,
            color: isPolicyIngest ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
          const SizedBox(width: AmDimens.gapS),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isPolicyIngest ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
