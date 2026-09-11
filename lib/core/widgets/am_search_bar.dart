import 'package:flutter/material.dart';
import 'am_spinner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Barra de búsqueda de las listas. Vivía en `features/clients/` pero la usan
/// clientes, catálogos y agenda — es transversal, y su lugar es `core/widgets/`.
class AmSearchBar extends StatelessWidget {
  const AmSearchBar({
    super.key,
    required this.onChanged,
    this.hintText,
    this.loading = false,
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final String? hintText;

  /// Muestra un giro discreto a la derecha mientras el servidor responde.
  ///
  /// Va AQUI y no reemplazando la lista: `AmLoader` es de pantalla completa, y
  /// usarlo aquí haría desaparecer los resultados en cada pausa al teclear —
  /// la app se sentiría más lenta de lo que es. El indicador vive donde ya
  /// estás mirando, que es el campo donde escribes.
  ///
  /// Las búsquedas locales (catálogos) lo dejan en false: no hay nada que
  /// esperar.
  final bool loading;

  /// Solo hace falta cuando alguien de afuera necesita BORRAR el texto — por
  /// ejemplo la agenda al cambiar de pestaña. Sin él, limpiar el estado dejaría
  /// la palabra escrita en la barra sin estar aplicada, que es peor que no
  /// limpiar nada.
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: AmColors.shadowSoft,
            blurRadius: 22,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: cs.onSurfaceVariant, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: hintText ?? l10n.clientsSearchHint,
                hintStyle: TextStyle(color: cs.tertiary),
              ),
            ),
          ),
          // Espacio reservado siempre, aparezca o no el giro: si el ancho
          // cambiara al empezar a buscar, el campo de texto daría un brinco
          // justo mientras el asesor escribe.
          SizedBox(
            width: 16,
            height: 16,
            child: loading
                ? AmSpinner(
                    size: 16,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
