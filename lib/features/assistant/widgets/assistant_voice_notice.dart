import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../l10n/app_localizations.dart';

/// Aviso de que la voz es experimental.
///
/// No es humildad de manual: el modelo de voz va atrás del de texto. En las
/// mismas pruebas donde el de texto cerró bien 4 de 4 compromisos, el de voz
/// cerró de más — y el asesor no tiene cómo saber que la diferencia existe.
///
/// Sin aviso, un error de voz se lee como "el asistente no sirve" y se lleva
/// entre las patas la confianza en el chat de texto, que sí es fiable. Con
/// aviso, se lee como lo que es: una función que está madurando.
///
/// Va ARRIBA de la barra y no dentro: ahí compite con el estado que dice de
/// quién es el turno, que es lo único que el asesor necesita leer rápido.
class AssistantVoiceNotice extends StatelessWidget {
  const AssistantVoiceNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AmDimens.gapXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 13, color: cs.tertiary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              l10n.voiceExperimental,
              style: TextStyle(fontSize: 11.5, color: cs.tertiary),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
