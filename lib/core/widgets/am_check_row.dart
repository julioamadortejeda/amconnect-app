import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';
import 'am_press.dart';

/// Fila con casilla + texto; toda la fila (texto incluido) es tocable.
/// Usa colores del tema: casilla rellena con `primary` al marcarse.
class AmCheckRow extends StatelessWidget {
  const AmCheckRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;

  /// null deshabilita la fila.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onChanged != null;
    return Semantics(
      checked: value,
      enabled: enabled,
      inMutuallyExclusiveGroup: false,
      label: label,
      excludeSemantics: true,
      onTap: enabled ? () => onChanged!(!value) : null,
      child: AmPress(
        scale: 0.98,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AmDimens.cardPad, vertical: AmDimens.gapS),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: value ? cs.primary : cs.outline,
                    width: 1.5,
                  ),
                ),
                child: value
                    ? Icon(Icons.check_rounded, size: 17, color: cs.onPrimary)
                    : null,
              ),
              const SizedBox(width: AmDimens.gapS),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: enabled ? cs.onSurface : cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
