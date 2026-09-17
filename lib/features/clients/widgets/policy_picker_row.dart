import 'package:flutter/material.dart';

import '../../../core/widgets/am_info_row.dart';

/// Fila del formulario de póliza cuyo valor se elige tocándola: una fecha del
/// selector, un cliente, un catálogo.
///
/// Existe porque el formulario tiene trece y entre ellas solo cambiaban el
/// ícono, la etiqueta y de dónde sale el valor. Lo que estaba copiado trece
/// veces era la regla de cómo se ve un campo sin llenar —más tenue y sin
/// peso—, que es justo lo que no debe divergir entre filas de la misma tarjeta.
class PolicyPickerRow extends StatelessWidget {
  const PolicyPickerRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.placeholder = '—',
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;

  /// El valor ya listo para mostrarse, o `null` si el asesor no lo ha elegido.
  final String? value;

  /// Lo que se ve mientras no hay valor. El guion por omisión sirve para las
  /// fechas; las filas que se eligen de una lista mandan su propio texto.
  final String placeholder;

  /// `null` deja la fila sin chevron y sin respuesta al toque — así se marca
  /// un campo que esta póliza no permite cambiar (el cliente, al editar).
  final VoidCallback? onTap;

  /// En `false` el valor se ve apagado aunque exista: el campo depende de otro
  /// que todavía no se elige (el producto necesita aseguradora y ramo).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filled = value != null;
    return AmInfoRow(
      icon: icon,
      label: label,
      trailing: Text(
        value ?? placeholder,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: filled ? FontWeight.w500 : FontWeight.w400,
          color: !enabled
              ? cs.tertiary.withValues(alpha: 0.5)
              : filled
                  ? cs.onSurface
                  : cs.tertiary,
        ),
      ),
      chevron: onTap != null,
      onTap: onTap,
    );
  }
}
