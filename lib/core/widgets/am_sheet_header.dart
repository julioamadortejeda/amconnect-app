import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';

/// Header estándar de bottom sheet: manija + título, con espacio opcional
/// para una acción a la derecha (ej. eliminar en un sheet de edición).
class AmSheetHeader extends StatelessWidget {
  const AmSheetHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: cs.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AmDimens.gapM),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                textAlign: trailing == null ? TextAlign.center : TextAlign.start,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AmDimens.gapM),
      ],
    );
  }
}
