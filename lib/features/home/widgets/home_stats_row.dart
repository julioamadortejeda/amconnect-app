import 'package:flutter/material.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/l10n/app_localizations.dart';

class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({
    super.key,
    required this.polizas,
    required this.porRenovar,
    required this.seguimientos,
  });
  final int polizas, porRenovar, seguimientos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final tiles = [
      (polizas.toString(), l10n.homePolicies),
      (porRenovar.toString(), l10n.homeToRenew),
      (seguimientos.toString(), l10n.homeSeguimientos),
    ];
    return AmCard(
      noPad: true,
      child: IntrinsicHeight(
        child: Row(
          children: tiles.asMap().entries.map((e) {
            final (value, label) = e.value;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                  border: e.key > 0
                      ? Border(left: BorderSide(color: cs.outlineVariant))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600,
                            color: cs.onSurface, letterSpacing: -0.02)),
                    const SizedBox(height: 3),
                    Text(label,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                            color: cs.tertiary)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
