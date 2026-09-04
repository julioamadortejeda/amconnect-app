import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/features.dart';
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

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final remindersAsync = ref.watch(remindersProvider);
    final ui = ref.watch(remindersUiProvider);
    final tab = ref.watch(agendaTabProvider);
    ref.watch(reminderTypesProvider); // pre-warm para evitar flash en filtros

    final onReminders = tab == AgendaTab.reminders;

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
                onSelect: (i) => ref
                    .read(agendaTabProvider.notifier)
                    .select(AgendaTab.values[i]),
              ),
            ),
            const SizedBox(height: AmDimens.gapS),
            Expanded(
              child: onReminders
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
