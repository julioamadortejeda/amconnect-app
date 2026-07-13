import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';

/// Fila de campo editable dentro de una card agrupada (label chico arriba,
/// TextField sin borde propio abajo) — para formularios donde varios campos
/// relacionados comparten un mismo contenedor, separados por [AmFormDivider].
class AmFormRow extends StatelessWidget {
  const AmFormRow({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AmDimens.screenH, vertical: AmDimens.gapXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(icon, size: 18, color: cs.tertiary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: cs.tertiary,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  minLines: minLines,
                  maxLines: maxLines,
                  style: TextStyle(fontSize: 15, color: cs.onSurface),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 2),
                    hintText: label,
                    hintStyle:
                        TextStyle(color: cs.tertiary.withValues(alpha: 0.55)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Separador entre [AmFormRow]/[AmInfoRow] dentro de una misma card.
class AmFormDivider extends StatelessWidget {
  const AmFormDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      indent: AmDimens.screenH,
      endIndent: AmDimens.screenH,
      color: cs.outlineVariant.withValues(alpha: 0.5),
    );
  }
}
