import 'package:flutter/material.dart';
import '../../../core/theme/app_dimensions.dart';

class ReminderInfoRow extends StatelessWidget {
  const ReminderInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
    this.chevron = false,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AmDimens.screenH, vertical: AmDimens.gapS),
      child: Row(children: [
        Icon(icon, size: 18, color: cs.tertiary),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: Text(label,
              style: TextStyle(fontSize: 13.5, color: cs.onSurfaceVariant)),
        ),
        Expanded(
            child:
                Align(alignment: Alignment.centerRight, child: trailing)),
        if (chevron && onTap != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 16, color: cs.tertiary),
        ],
      ]),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AmDimens.cardRadius),
      child: row,
    );
  }
}
