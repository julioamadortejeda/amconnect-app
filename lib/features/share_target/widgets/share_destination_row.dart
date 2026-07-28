import 'package:flutter/material.dart';
import '../../../core/theme/app_dimensions.dart';
import '../providers/share_target_provider.dart';

/// Una opción de destino dentro de `ShareDestinationSelector`: radio + icono +
/// título, con el registro elegido (o una pista) debajo y la acción para
/// abrir su selector a la derecha.
class ShareDestinationRow extends StatelessWidget {
  const ShareDestinationRow({
    super.key,
    required this.type,
    required this.selectedType,
    required this.icon,
    required this.title,
    required this.onSelect,
    this.hint,
    this.value,
    this.actionLabel,
    this.onAction,
    this.loading = false,
    this.enabled = true,
  });

  final ShareDestinationType type;
  final ShareDestinationType selectedType;
  final IconData icon;
  final String title;
  final VoidCallback onSelect;

  /// Texto secundario fijo (ej. de qué va el destino o por qué no aplica).
  final String? hint;

  /// Registro ya elegido — tiene prioridad sobre `hint`.
  final String? value;

  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSelected = enabled && selectedType == type;

    final titleColor = !enabled
        ? cs.tertiary
        : isSelected
            ? cs.onSurface
            : cs.onSurfaceVariant;

    return InkWell(
      onTap: enabled ? onSelect : null,
      borderRadius: BorderRadius.circular(AmDimens.gapS),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AmDimens.gapS, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? cs.primary
                      : enabled
                          ? cs.outline
                          : cs.outlineVariant,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
            const SizedBox(width: AmDimens.gapM),
            Icon(icon, size: 16, color: isSelected ? cs.primary : cs.tertiary),
            const SizedBox(width: AmDimens.gapS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  if (value != null && value!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      value!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (hint != null && hint!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      hint!,
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.tertiary),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected && onAction != null && actionLabel != null)
              TextButton(
                // Mientras la cartera no termine de cargar no hay nada que
                // ofrecer en el selector: se deja visible pero inerte.
                onPressed: loading ? null : onAction,
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
