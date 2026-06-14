import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/reminder.dart';
import '../../../core/models/reminder_type.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/reminder_utils.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/providers/home_provider.dart';

class ReminderTypeSelectionSheet extends ConsumerWidget {
  const ReminderTypeSelectionSheet({
    super.key,
    required this.reminder,
    required this.types,
  });

  final Reminder reminder;
  final List<ReminderType> types;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final sl10n = AppLocalizations.of(context)!;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AmDimens.gapM,
              AmDimens.gapXS,
              AmDimens.gapM,
              0,
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AmDimens.gapM),
                Text(
                  sl10n.remindersDetailSelectType,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: AmDimens.gapXS),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AmDimens.gapM,
                  0,
                  AmDimens.gapM,
                  AmDimens.gapM,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: types.map((t) {
                    final isCurrent = t.id == reminder.typeId;
                    return ListTile(
                      leading: Icon(
                        reminderIcon(t.code),
                        color: isCurrent ? cs.primary : cs.onSurfaceVariant,
                      ),
                      title: Text(
                        sl10n.reminderType(t.code),
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                          color: isCurrent ? cs.primary : cs.onSurface,
                        ),
                      ),
                      trailing: isCurrent
                          ? Icon(Icons.check, color: cs.primary, size: 20)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
                      ),
                      onTap: isCurrent
                          ? null
                          : () {
                              Navigator.pop(context);
                              ref.read(remindersProvider.notifier).updateType(
                                    reminder.id,
                                    t.id,
                                  );
                            },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          SafeArea(child: const SizedBox.shrink()),
        ],
      ),
    );
  }
}
