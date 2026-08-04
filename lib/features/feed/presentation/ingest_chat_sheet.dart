import 'package:flutter/material.dart';
import '../../../core/widgets/am_spinner.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../assistant/providers/assistant_provider.dart';
import '../providers/ingest_provider.dart';

class IngestChatSheet extends ConsumerWidget {
  const IngestChatSheet({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(ingestProvider);

    final extraction = state.extraction ?? {};
    final policyNumber = extraction['policyNumber'] as String?;
    final carrierName = extraction['carrierName'] as String?;
    // El banner de duplicado debe mostrar la explicación de la IA, no lo
    // último en la lista — tras tocar "Sí, guardar" el último mensaje es el
    // "Sí" del usuario, y sin esto el banner lo mostraría a él en su lugar.
    final aiMessages = state.messages.where((m) => m.role == 'ai');
    final lastAiText = aiMessages.isEmpty ? '' : aiMessages.last.text;

    return Container(
      color: AmColors.scrim,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AmDimens.cardRadius)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Handle + header
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Column(
                  children: [
                    Container(
                      width: 44, height: 5,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: AmDimens.gapM),
                    Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AmColors.accent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/logo/logo.png',
                              color: Colors.white,
                              width: 18,
                              height: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.feedConfirmPolicyTitle,
                                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600,
                                      color: cs.onSurface)),
                              if (policyNumber != null || carrierName != null)
                                Text(
                                  [if (carrierName != null) carrierName,
                                   if (policyNumber != null) '# $policyNumber'].join(' · '),
                                  style: TextStyle(fontSize: 12, color: cs.tertiary),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: cs.tertiary, size: 20),
                          onPressed: onClose,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AmDimens.gapXS),
                    Divider(height: 1, color: cs.outlineVariant),
                  ],
                ),
              ),

              // Main body area
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: AmDimens.gapM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.isDuplicate && lastAiText.isNotEmpty) ...[
                        _AttentionBanner(text: lastAiText),
                        const SizedBox(height: AmDimens.gapM),
                      ],
                      if (state.contactMismatchResolvedToScreen == true && state.contactMismatch != null) ...[
                        _AttentionBanner(
                          text: l10n.feedContactMismatchResolvedBanner(
                            state.contactMismatch!.screenContactName,
                            state.contactMismatch!.detectedContactName,
                          ),
                        ),
                        const SizedBox(height: AmDimens.gapM),
                      ],
                      _PolicySummaryCard(extraction: extraction, l10n: l10n),
                      const SizedBox(height: AmDimens.gapL),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AmColors.accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: state.isSending
                              ? null
                              : () {
                                  ref.read(ingestProvider.notifier).sendMessage('Sí');
                                },
                          child: state.isSending
                              ? const AmSpinner(
                                  size: 20,
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                )
                              : Text(
                                  l10n.feedIngestConfirmCta,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                      const SizedBox(height: AmDimens.gapS),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.onSurface,
                                side: BorderSide(color: cs.outlineVariant),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                              label: Text(l10n.feedIngestCorrectCta, style: const TextStyle(fontSize: 13)),
                              onPressed: state.sessionId == null
                                  ? null
                                  : () {
                                      final resumeArgs = AssistantResumeArgs(
                                        sessionId: state.sessionId!,
                                        messages: state.messages
                                            .map((m) => AssistantMessage(role: m.role, text: m.text))
                                            .toList(),
                                      );
                                      // Cerramos el sheet antes de navegar — mantenerlo
                                      // vivo debajo del Assistant causaba crashes de
                                      // Riverpod al pausar/reanudar providers al apilar
                                      // rutas. La IA ya confirma la póliza en el propio
                                      // chat, no hace falta el PolicySuccessSheet aquí.
                                      ref.read(ingestProvider.notifier).closeForAssistantHandoff();
                                      GoRouter.of(context).push('/chat', extra: resumeArgs);
                                    },
                            ),
                          ),
                          const SizedBox(width: AmDimens.gapS),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.error,
                                side: BorderSide(color: cs.error.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: onClose,
                              child: Text(l10n.feedIngestCancelCta, style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Error notification
              if (state.error != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, AmDimens.gapXS),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(context.translateError(state.error!),
                      style: TextStyle(fontSize: 12.5, color: cs.error)),
                ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttentionBanner extends StatelessWidget {
  const _AttentionBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    return Container(
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
            child: MarkdownBody(
              data: text,
              shrinkWrap: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: TextStyle(fontSize: 13, color: cs.onSurface, height: 1.4),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                listBullet: TextStyle(color: am.amber),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySummaryCard extends StatelessWidget {
  final Map<String, dynamic> extraction;
  final AppLocalizations l10n;

  const _PolicySummaryCard({required this.extraction, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final policyNumber = extraction['policyNumber'] as String? ?? '—';
    final carrierName = extraction['carrierName'] as String? ?? '—';
    final branchName = extraction['branchName'] as String? ?? '—';
    final productName = extraction['productName'] as String? ?? '—';
    final holderName = extraction['holderName'] as String? ?? '—';
    final premium = (extraction['premium'] as num?)?.toDouble();
    final currency = extraction['currency'] as String? ?? 'MXN';
    final startDate = extraction['startDate'] as String?;
    final endDate = extraction['endDate'] as String?;

    return Container(
      padding: const EdgeInsets.all(AmDimens.cardPad),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(label: l10n.feedIngestHolderLabel, value: holderName, isBold: true),
          const SizedBox(height: AmDimens.gapS),
          _SummaryRow(label: l10n.feedIngestCarrierLabel, value: carrierName),
          const SizedBox(height: AmDimens.gapS),
          _SummaryRow(label: l10n.feedIngestBranchProductLabel, value: '$branchName · $productName'),
          const SizedBox(height: AmDimens.gapS),
          _SummaryRow(label: l10n.feedIngestPolicyNumberLabel, value: policyNumber),
          const SizedBox(height: AmDimens.gapS),
          _SummaryRow(
            label: l10n.feedIngestPremiumLabel,
            value: premium != null ? '${fmtCurrency(premium)} $currency' : '—',
          ),
          const SizedBox(height: AmDimens.gapS),
          _SummaryRow(
            label: l10n.feedIngestValidityLabel,
            value: '${fmtDateFromIso(startDate)} – ${fmtDateFromIso(endDate)}',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: cs.tertiary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
