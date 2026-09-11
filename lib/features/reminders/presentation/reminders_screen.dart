import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/features.dart';
import '../widgets/agenda_search_results.dart';
import '../../../core/widgets/am_search_bar.dart';
import '../../../core/providers/commitments_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_sliding_tabs.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../../home/providers/home_provider.dart';
import '../providers/reminders_provider.dart';
import '../widgets/commitment_list_view.dart';
import '../widgets/reminder_calendar_view.dart';
import '../widgets/reminder_list_view.dart';
import '../../../l10n/app_localizations.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  /// La agenda es dueña del texto para poder borrarlo al cambiar de pestaña.
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final remindersAsync = ref.watch(remindersProvider);
    final ui = ref.watch(remindersUiProvider);
    final tab = ref.watch(agendaTabProvider);
    ref.watch(reminderTypesProvider); // pre-warm para evitar flash en filtros

    final onReminders = tab == AgendaTab.reminders;
    final buscando = ref.watch(agendaSearchProvider).isNotEmpty;
    // El giro de la barra, no un loader de pantalla: cambiar toda la lista por
    // un indicador en cada pausa al teclear se siente peor que esperar.
    final busqueda = onReminders
        ? ref.watch(reminderSearchProvider)
        : ref.watch(commitmentSearchProvider);
    final cargandoBusqueda = buscando && busqueda.isLoading;
    // Los resultados solo reemplazan la lista cuando YA hay algo que poner.
    // Mientras llega la primera tanda se queda lo que el asesor está viendo y
    // solo gira la barra: el logo de `AmLoader` es para un arranque en frío, y
    // usarlo aquí vaciaba la pantalla por medio segundo con dos indicadores
    // diciendo lo mismo.
    final mostrarResultados =
        buscando && (busqueda.hasValue || busqueda.hasError);

    final pendingCount =
        remindersAsync.asData?.value.where((r) => !r.done).length ?? 0;
    final openCommitments =
        ref.watch(commitmentsProvider).asData?.value.length ?? 0;

    return Scaffold(
      appBar: AmTopBar(
        title: l10n.remindersTitle,
        subtitle: onReminders
            ? l10n.remindersPendingCount(pendingCount)
            : l10n.commitmentsOpenCount(openCommitments),
        actions: [
          // Ajustes y calendario son de los recordatorios: los compromisos no
          // tienen tipos que configurar ni día que pintar en un calendario.
          if (onReminders) ...[
            AmPress(
              onTap: () => context.push('/reminder-settings'),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AmPress(
              onTap: () =>
                  ref.read(remindersUiProvider.notifier).toggleViewMode(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  ui.viewMode == RemindersViewMode.list
                      ? Icons.calendar_month_outlined
                      : Icons.view_list_outlined,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
          // El "+" cambia de destino con la pestaña, como en Portafolio. En
          // compromisos abre el asistente en vez de un formulario: es la única
          // forma de crear uno, y el botón lo enseña sin explicarlo.
          if (!onReminders || kManualReminderCreationEnabled) ...[
            const SizedBox(width: 10),
            AmPress(
              onTap: () => context
                  .push(onReminders ? '/create-reminder' : '/chat'),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AmColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
          const SizedBox(width: AmDimens.screenH),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: AmDimens.gapS),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
              child: AmSlidingTabs(
                labels: [l10n.agendaTabReminders, l10n.agendaTabCommitments],
                selected: tab.index,
                onSelect: (i) {
                  // Las dos pestañas son listas distintas. Arrastrar la
                  // búsqueda deja al asesor en "nada coincide" sin haber
                  // escrito ahí — buscar "pago" en recordatorios y caer en
                  // compromisos vacíos parece que la app se rompió.
                  _busqueda.clear();
                  ref.read(agendaSearchProvider.notifier).set('');
                  ref
                      .read(agendaTabProvider.notifier)
                      .select(AgendaTab.values[i]);
                },
              ),
            ),
            const SizedBox(height: AmDimens.gapS),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
              child: AmSearchBar(
                controller: _busqueda,
                hintText: l10n.agendaSearchHint,
                loading: cargandoBusqueda,
                onChanged: (t) =>
                    ref.read(agendaSearchProvider.notifier).set(t),
              ),
            ),
            const SizedBox(height: AmDimens.gapS),
            // Mientras hay texto, los resultados reemplazan a la lista: sus
            // filtros por tipo y el calendario no aplican a una búsqueda que el
            // asesor ya acotó con sus palabras.
            Expanded(
              child: mostrarResultados
                  ? const AgendaSearchResults()
                  : onReminders
                  ? remindersAsync.when(
                      loading: () => const AmLoader(),
                      error: (_, __) => Center(
                        child: Text(l10n.remindersError,
                            style: TextStyle(color: cs.tertiary)),
                      ),
                      data: (_) => ui.viewMode == RemindersViewMode.list
                          ? const ReminderListView()
                          : const ReminderCalendarView(),
                    )
                  : const CommitmentListView(),
            ),
            const SizedBox(height: AmDimens.gapM),
          ],
        ),
      ),
    );
  }
}
