import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/reminder_type.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../../../core/widgets/am_card.dart';
import '../providers/reminders_provider.dart';
import 'deleted_reminders_view.dart';
import 'reminder_filter_chip.dart';
import 'reminder_item.dart';
import '../../../l10n/app_localizations.dart';

const _typeOrder = [
  'PAYMENT', 'RENEWAL', 'CANCELLATION',
  'FOLLOW_UP', 'CALL', 'APPOINTMENT', 'ANNIVERSARY', 'OTHER',
];

int _typePriority(ReminderType t) {
  final i = _typeOrder.indexOf(t.code);
  return i == -1 ? _typeOrder.length : i;
}

class ReminderListView extends ConsumerWidget {
  const ReminderListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final ui = ref.watch(remindersUiProvider);
    final reminders = ref.watch(filteredRemindersProvider);
    final typesAsync = ref.watch(reminderTypesProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
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
                  data: (types) => (List.of(types)
                        ..sort((a, b) => _typePriority(a).compareTo(_typePriority(b))))
                      .map((t) => Padding(
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
          ),
          if (ui.filter == 'eliminados') ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: cs.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.remindersDeletedWarning,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (ui.filter == 'eliminados')
            const DeletedRemindersView()
          else
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
              child: reminders.isEmpty
                  ? Text(
                      l10n.remindersEmpty,
                      style: TextStyle(fontSize: 14, color: cs.tertiary),
                    )
                  : AmCard(
                      noPad: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < reminders.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 0,
                                indent: AmDimens.screenH,
                                endIndent: AmDimens.screenH,
                                color: cs.outlineVariant,
                              ),
                            ReminderItem(reminder: reminders[i]),
                          ],
                        ],
                      ),
                    ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
