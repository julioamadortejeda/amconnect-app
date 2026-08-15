import 'package:flutter/material.dart';
import '../../../core/models/reminder_type.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/reminder_utils.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../../../l10n/app_localizations.dart';

class ReminderTypeSelectionSheet extends StatelessWidget {
  const ReminderTypeSelectionSheet({
    super.key,
    required this.types,
    required this.onSelect,
    this.selectedTypeId,
  });

  final List<ReminderType> types;
  final String? selectedTypeId;
  final ValueChanged<ReminderType> onSelect;

  @override
  Widget build(BuildContext context) {
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
                    final isCurrent = t.id == selectedTypeId;
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
                              onSelect(t);
                            },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SafeArea(child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
