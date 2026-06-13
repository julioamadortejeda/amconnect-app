import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/reminder.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_card.dart';
import '../../../core/widgets/am_section_label.dart';
import '../providers/reminders_provider.dart';
import 'reminder_item.dart';
import '../../../l10n/app_localizations.dart';

class DeletedRemindersView extends ConsumerWidget {
  const DeletedRemindersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(filteredRemindersProvider);

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
        child: Text(l10n.remindersEmpty,
            style: TextStyle(fontSize: 14, color: cs.tertiary)),
      );
    }

    final groups = _groupByType(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
            child: AmSectionLabel(label: entry.key),
          ),
          const SizedBox(height: 6),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
            child: Opacity(
              opacity: 0.65,
              child: AmCard(
                noPad: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < entry.value.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 0,
                          indent: AmDimens.screenH,
                          endIndent: AmDimens.screenH,
                          color: cs.outlineVariant,
                        ),
                      IgnorePointer(
                        child: ReminderItem(reminder: entry.value[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AmDimens.gapM),
        ],
      ],
    );
  }

  Map<String, List<Reminder>> _groupByType(List<Reminder> items) {
    final map = <String, List<Reminder>>{};
    for (final r in items) {
      (map[r.typeName] ??= []).add(r);
    }
    return map;
  }
}
