import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/commitments_provider.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_commitments_card.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_stagger.dart';
import '../../../l10n/app_localizations.dart';

/// La mitad sin calendario de la Agenda.
///
/// No lleva selector de filtros como su hermana de recordatorios: un compromiso
/// solo tiene dos estados que le importen al asesor —abierto o cerrado— y los
/// cerrados no se consultan, se olvidan. Filtrar una lista de cuatro cosas es
/// darle trabajo al asesor para no ahorrarle ninguno.
///
/// La cita textual sí se muestra aquí, a diferencia del dashboard: allá cuesta
/// un renglón por fila en el espacio más caro de la app, y aquí es lo que el
/// asesor viene a leer cuando ya no se acuerda de qué se trataba.
class CommitmentListView extends ConsumerWidget {
  const CommitmentListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return ref.watch(commitmentsProvider).when(
          loading: () => const AmLoader(),
          error: (_, __) => Center(
            child: Text(l10n.commitmentsError,
                style: TextStyle(color: cs.tertiary)),
          ),
          data: (commitments) {
            if (commitments.isEmpty) {
              return Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
                  // Dos bloques y no uno de tres renglones: el primero enseña a
                  // CREAR, el segundo a CORREGIR. Este segundo existe porque el
                  // asistente a veces guarda una nota donde iba un compromiso, y
                  // se arregla hablándole — pero el asesor no tiene cómo saberlo
                  // si nadie se lo dice. Más apagado a propósito: es la salida de
                  // emergencia, no la instrucción principal.
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.commitmentsEmptyHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.tertiary, height: 1.4),
                      ),
                      const SizedBox(height: AmDimens.gapM),
                      Text(
                        l10n.commitmentsEmptyFix,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: cs.tertiary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(AmDimens.screenH, 0,
                  AmDimens.screenH, AmDimens.scrollBottomPad),
              children: [
                AmAnimateIn(
                  index: 0,
                  child: AmCommitmentsCard(
                    commitments: commitments,
                    showQuote: true,
                    maxVisible: null,
                  ),
                ),
              ],
            );
          },
        );
  }
}
