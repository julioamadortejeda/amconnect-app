import 'package:flutter/material.dart';
import '../../../core/models/reminder_setting.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../../../core/utils/reminder_utils.dart';
import '../../../core/widgets/am_form_row.dart';
import '../../../core/widgets/am_group_card.dart';
import '../../../core/widgets/am_info_row.dart';
import '../../../core/widgets/am_press.dart';
import '../../../l10n/app_localizations.dart';

/// Traduce la anticipación a texto: 0 días es "el mismo día", no "0 días antes".
String reminderAdvanceLabel(AppLocalizations l10n, int daysBefore) =>
    daysBefore == 0 ? l10n.reminderSettingsSameDay : l10n.reminderSettingsDaysBefore(daysBefore);

/// Un tipo de aviso con su anticipación, su switch y sus excepciones por ramo.
class ReminderSettingCard extends StatelessWidget {
  const ReminderSettingCard({
    super.key,
    required this.setting,
    required this.onChangeDays,
    required this.onToggle,
    required this.onAddException,
    required this.onChangeOverrideDays,
  });

  final ReminderSetting setting;
  final VoidCallback onChangeDays;
  final ValueChanged<bool> onToggle;
  final VoidCallback onAddException;
  final ValueChanged<ReminderSettingOverride> onChangeOverrideDays;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AmGroupCard(children: [
      AmInfoRow(
        icon: reminderIcon(setting.typeCode),
        label: l10n.reminderType(setting.typeCode),
        trailing: Switch(value: setting.isActive, onChanged: onToggle),
      ),
      const AmFormDivider(),
      AmInfoRow(
        icon: Icons.schedule_outlined,
        label: l10n.reminderSettingsDefault,
        trailing: Text(
          setting.isActive ? reminderAdvanceLabel(l10n, setting.daysBefore) : l10n.reminderSettingsOff,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: setting.isActive ? cs.onSurface : cs.tertiary,
          ),
        ),
        chevron: setting.isActive,
        onTap: setting.isActive ? onChangeDays : null,
      ),
      if (setting.isActive) ...[
        for (final override in setting.overrides) ...[
          const AmFormDivider(),
          AmInfoRow(
            icon: Icons.tune_outlined,
            label: override.branchName,
            trailing: Text(
              override.isActive
                  ? reminderAdvanceLabel(l10n, override.daysBefore)
                  : l10n.reminderSettingsOff,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: override.isActive ? cs.onSurface : cs.tertiary,
              ),
            ),
            chevron: true,
            onTap: () => onChangeOverrideDays(override),
          ),
        ],
        const AmFormDivider(),
        AmPress(
          onTap: onAddException,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AmDimens.screenH, vertical: AmDimens.gapS),
            child: Row(
              children: [
                Icon(Icons.add, size: 18, color: cs.primary),
                const SizedBox(width: AmDimens.gapS),
                Text(
                  l10n.reminderSettingsAddException,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ]);
  }
}
