import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../../../core/utils/reminder_utils.dart';
import '../providers/reminders_provider.dart';
import 'reminder_filter_chip.dart';
import '../../../l10n/app_localizations.dart';

/// Filtro de recordatorios como fila de chips horizontal — implementación
/// original, conservada como alternativa a [ReminderFilterSelector]. No se
/// usa hoy en `ReminderListView` pero se deja disponible.
class ReminderFilterChipsRow extends ConsumerWidget {
  const ReminderFilterChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ui = ref.watch(remindersUiProvider);
    final typesAsync = ref.watch(reminderTypesProvider);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ReminderFilterChip(
              label: l10n.remindersFilterAll,
              active: ui.filter == 'todos',
              onTap: () =>
                  ref.read(remindersUiProvider.notifier).setFilter('todos'),
            ),
          ),
          ...typesAsync.maybeWhen(
            data: (types) => sortReminderTypes(types).map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ReminderFilterChip(
                    label: l10n.reminderType(t.code),
                    active: ui.filter == t.code,
                    onTap: () => ref
                        .read(remindersUiProvider.notifier)
                        .setFilter(t.code),
                  ),
                )),
            orElse: () => [],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ReminderFilterChip(
              label: l10n.remindersFilterCompleted,
              active: ui.filter == 'completados',
              onTap: () => ref
                  .read(remindersUiProvider.notifier)
                  .setFilter('completados'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ReminderFilterChip(
              label: l10n.remindersFilterDeleted,
              active: ui.filter == 'eliminados',
              danger: true,
              onTap: () => ref
                  .read(remindersUiProvider.notifier)
                  .setFilter('eliminados'),
            ),
          ),
        ],
      ),
    );
  }
}
