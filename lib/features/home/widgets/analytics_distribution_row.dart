import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Fila de distribución (nombre + conteo/porcentaje + barra) para ramos y aseguradoras.
class AnalyticsDistributionRow extends StatelessWidget {
  const AnalyticsDistributionRow({
    super.key,
    required this.name,
    required this.count,
    required this.total,
  });

  final String name;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double percent = total > 0 ? count / total : 0.0;
    final int pctLabel = (percent * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$count ($pctLabel%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: cs.secondaryContainer,
            valueColor: const AlwaysStoppedAnimation<Color>(AmColors.accent),
          ),
        ),
      ],
    );
  }
}
