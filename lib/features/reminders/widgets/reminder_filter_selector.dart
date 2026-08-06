import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../../../core/utils/reminder_utils.dart';
import '../../../core/widgets/am_press.dart';
import '../providers/reminders_provider.dart';
import 'reminder_filter_selection_sheet.dart';
import '../../../l10n/app_localizations.dart';

/// Selector compacto del filtro de recordatorios — toca para abrir un sheet
/// con la lista completa, mismo patrón que `ReminderTypeSelectionSheet` /
/// `ReminderStatusSelectionSheet`. Alternativa a [ReminderFilterChipsRow].
class ReminderFilterSelector extends ConsumerWidget {
  const ReminderFilterSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final ui = ref.watch(remindersUiProvider);

    final (label, icon, color) = switch (ui.filter) {
      'todos' => (
          l10n.remindersFilterAll,
          Icons.list_alt_outlined,
          cs.onSurfaceVariant
        ),
      'completados' => (
          l10n.remindersFilterCompleted,
          Icons.check_circle_outline,
          am.green
        ),
      'eliminados' => (
          l10n.remindersFilterDeleted,
          Icons.delete_outline,
          cs.error
        ),
      final code => (
          l10n.reminderType(code),
          reminderIcon(code),
          cs.onSurfaceVariant,
        ),
    };

    return AmPress(
      onTap: () => showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => ReminderFilterSelectionSheet(
          selectedFilter: ui.filter,
          onSelect: (v) => ref.read(remindersUiProvider.notifier).setFilter(v),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(11),
          boxShadow: const [
            BoxShadow(color: AmColors.shadowSoft, blurRadius: 8)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: cs.tertiary),
          ],
        ),
      ),
    );
  }
}
