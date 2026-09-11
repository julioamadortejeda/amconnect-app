import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_stagger.dart';
import '../../../core/widgets/am_commitments_card.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/reminders_provider.dart';
import 'reminder_grouped_list.dart';

/// Lo que se ve en la agenda mientras hay texto en la búsqueda.
///
/// Widget aparte y no un modo dentro de `ReminderListView`: la lista normal
/// vive de filtros locales sobre lo ya cargado, y esto viene del servidor. Son
/// dos fuentes distintas y mezclarlas volvería confuso de dónde salió cada fila.
///
/// Los filtros por tipo y la vista de calendario NO aplican aquí: buscar es una
/// pregunta que el asesor ya acotó con sus palabras.
class AgendaSearchResults extends ConsumerWidget {
  const AgendaSearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final enRecordatorios = ref.watch(agendaTabProvider) == AgendaTab.reminders;

    Widget vacio(String texto) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
            child: Text(texto,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: cs.tertiary)),
          ),
        );

    Widget error() => vacio(l10n.remindersError);

    if (enRecordatorios) {
      return ref.watch(reminderSearchProvider).when(
            // `skipLoadingOnReload` conserva lo encontrado mientras llega la
            // siguiente tanda: al agregar una letra la lista se afina en vez de
            // parpadear. Y la pantalla ni siquiera monta este widget hasta que
            // hay datos, así que esta rama solo cubre un caso imposible.
            skipLoadingOnReload: true,
            loading: () => const SizedBox.shrink(),
            error: (_, __) => error(),
            data: (encontrados) => encontrados.isEmpty
                ? vacio(l10n.agendaSearchEmpty)
                : ReminderGroupedList(reminders: encontrados),
          );
    }

    return ref.watch(commitmentSearchProvider).when(
          skipLoadingOnReload: true,
          loading: () => const SizedBox.shrink(),
          error: (_, __) => error(),
          data: (encontrados) => encontrados.isEmpty
              ? vacio(l10n.agendaSearchEmpty)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(AmDimens.screenH, 0,
                      AmDimens.screenH, AmDimens.scrollBottomPad),
                  children: [
                    AmAnimateIn(
                      index: 0,
                      child: AmCommitmentsCard(
                        commitments: encontrados,
                        showQuote: true,
                        maxVisible: null,
                      ),
                    ),
                  ],
                ),
        );
  }
}
