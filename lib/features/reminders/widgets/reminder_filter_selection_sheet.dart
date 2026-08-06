import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../../../core/utils/reminder_utils.dart';
import '../providers/reminders_provider.dart';
import '../../../l10n/app_localizations.dart';

class _FilterOption {
  const _FilterOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
}

class ReminderFilterSelectionSheet extends ConsumerWidget {
  const ReminderFilterSelectionSheet({
    super.key,
    required this.selectedFilter,
    required this.onSelect,
  });

  final String selectedFilter;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    // Watch en vivo (no recibir `types` congelado del caller) — si el
    // catálogo todavía estaba cargando cuando se abrió el sheet, este watch
    // sí lo actualiza en cuanto llegue; una lista fija se hubiera quedado
    // vacía para siempre en ese caso.
    final types = ref.watch(reminderTypesProvider).asData?.value ?? [];

    final options = [
      _FilterOption(
        value: 'todos',
        label: l10n.remindersFilterAll,
        icon: Icons.list_alt_outlined,
        color: cs.onSurfaceVariant,
      ),
      for (final t in sortReminderTypes(types))
        _FilterOption(
          value: t.code,
          label: l10n.reminderType(t.code),
          icon: reminderIcon(t.code),
          color: cs.onSurfaceVariant,
        ),
      _FilterOption(
        value: 'completados',
        label: l10n.remindersFilterCompleted,
        icon: Icons.check_circle_outline,
        color: am.green,
      ),
      _FilterOption(
        value: 'eliminados',
        label: l10n.remindersFilterDeleted,
        icon: Icons.delete_outline,
        color: cs.error,
      ),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                  l10n.remindersFilterSelectTitle,
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
                  children: options.map((o) {
                    final isCurrent = o.value == selectedFilter;
                    return ListTile(
                      leading:
                          Icon(o.icon, color: isCurrent ? cs.primary : o.color),
                      title: Text(
                        o.label,
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.w600 : FontWeight.normal,
                          color: isCurrent ? cs.primary : cs.onSurface,
                        ),
                      ),
                      trailing: isCurrent
                          ? Icon(Icons.check, color: cs.primary, size: 20)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AmDimens.cardRadius),
                      ),
                      onTap: isCurrent
                          ? null
                          : () {
                              Navigator.pop(context);
                              onSelect(o.value);
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
