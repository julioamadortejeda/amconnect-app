import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Card contenedora para agrupar varias filas relacionadas (ej. varios
/// [AmFormRow]/[AmInfoRow] separados por [AmFormDivider]) bajo un mismo
/// contenedor visual, en vez de una card por campo.
class AmGroupCard extends StatelessWidget {
  const AmGroupCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        boxShadow: AmShadows.card,
      ),
      child: Column(children: children),
    );
  }
}
