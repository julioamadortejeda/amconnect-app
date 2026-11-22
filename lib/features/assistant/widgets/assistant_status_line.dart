import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'thinking_pulse.dart';

/// Línea de estado mientras el asistente trabaja con una herramienta
/// ("Buscando cliente…"). [label] ya viene localizado del backend; nunca se
/// muestra el nombre técnico de la herramienta. Convive con
/// [AssistantTypingBubble] (que se usa cuando no hay etiqueta): no lo
/// reemplaza.
class AssistantStatusLine extends StatelessWidget {
  const AssistantStatusLine({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ThinkingPulse(color: AmColors.accent, size: 16),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.tertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
