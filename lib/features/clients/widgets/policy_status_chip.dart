import 'package:flutter/material.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../../../l10n/app_localizations.dart';

class PolicyStatusChip extends StatelessWidget {
  const PolicyStatusChip({
    super.key,
    required this.statusCode,
    this.rawName,
  });

  final String statusCode;
  final String? rawName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;

    final code = statusCode.toUpperCase().trim();

    final (label, color) = switch (code) {
      'ACTIVE' || 'VIGENTE' => (l10n.policyStatus('ACTIVE'), am.green),
      'PENDING' || 'EN_TRAMITE' || 'EN TRAMITE' => (l10n.policyStatus('PENDING'), am.amber),
      'CANCELLED' || 'CANCELADA' => (l10n.policyStatus('CANCELLED'), cs.error),
      'EXPIRED' || 'VENCIDA' => (l10n.policyStatus('EXPIRED'), cs.error),
      'SUSPENDED' || 'SUSPENDIDA' => (l10n.policyStatus('SUSPENDED'), cs.tertiary),
      _ => (rawName ?? (code.isNotEmpty ? l10n.policyStatus(code) : '—'), cs.tertiary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
