import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';

/// Encabezado estándar de las hojas inferiores: manija, título y subtítulo.
///
/// Estaba copiado en cada hoja. Vive aquí para que todas abran igual — si
/// alguien cambia la manija, cambia en todas.
class AmSheetHeader extends StatelessWidget {
  const AmSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.titleMaxLines = 1,
  });

  final String title;
  final String? subtitle;

  /// Para cuando el subtítulo carga significado — la urgencia de un
  /// compromiso, por ejemplo. Sin esto usa el gris de siempre.
  final Color? subtitleColor;

  /// Uno por omisión. Las hojas que existen PARA que se lea el texto completo
  /// —la de compromisos— pasan null.
  final int? titleMaxLines;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
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
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.3,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
          maxLines: titleMaxLines,
          overflow:
              titleMaxLines == null ? null : TextOverflow.ellipsis,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 12.5,
              color: subtitleColor ?? cs.tertiary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Un mosaico de acción dentro de una hoja. Va dentro de un [Row]; se expande
/// solo para repartirse el ancho con sus hermanos.
///
/// SIN borde, a propósito: relleno y contorno dicen lo mismo —"esto es un
/// objeto aparte"— y usar los dos en cada elemento aplana la jerarquía, todo
/// termina pesando igual. Se queda el relleno, que es el que además comunica
/// que se puede tocar.
class AmSheetTile extends StatelessWidget {
  const AmSheetTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Color del icono. Por omisión el primario del tema.
  final Color? color;

  /// Segunda línea en rojo — para advertir de lo que la acción va a costar.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color ?? cs.primary, size: 26),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: cs.error,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
