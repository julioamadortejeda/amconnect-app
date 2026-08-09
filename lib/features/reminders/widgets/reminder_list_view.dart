import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_dimensions.dart';
import '../providers/reminders_provider.dart';
import 'deleted_reminders_view.dart';
import 'reminder_filter_selector.dart';
import 'reminder_grouped_list.dart';
import '../../../core/widgets/am_stagger.dart';
import '../../../l10n/app_localizations.dart';

class ReminderListView extends ConsumerWidget {
  const ReminderListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final ui = ref.watch(remindersUiProvider);
    final reminders = ref.watch(filteredRemindersProvider);

    return Column(
      children: [
        AmAnimateIn(
          index: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ReminderFilterSelector(),
            ),
          ),
        ),
        if (ui.filter == 'eliminados') ...[
          const SizedBox(height: AmDimens.gapXS),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: cs.error),
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
        const SizedBox(height: AmDimens.gapS),
        Expanded(
          child: reminders.isEmpty
              ? Center(
                  child: Text(
                    l10n.remindersEmpty,
                    style: TextStyle(fontSize: 14, color: cs.tertiary),
                  ),
                )
              : (ui.filter == 'eliminados' || ui.filter == 'completados')
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.only(
                          bottom: AmDimens.scrollBottomPad),
                      child: const DeletedRemindersView(),
                    )
                  : ReminderGroupedList(reminders: reminders),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
