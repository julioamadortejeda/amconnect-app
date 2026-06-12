import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_press.dart';
import '../../home/providers/home_provider.dart';
import '../providers/reminders_provider.dart';
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

    final pendingCount = remindersAsync.asData?.value
            .where((r) => !r.done)
            .length ??
        0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AmDimens.screenH, 12, AmDimens.screenH, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.remindersPendingCount(pendingCount),
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: cs.tertiary),
                        ),
                        Text(
                          l10n.remindersTitle,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                              letterSpacing: -0.01),
                        ),
                      ],
                    ),
                  ),
                  AmPress(
                    onTap: () => ref
                        .read(remindersUiProvider.notifier)
                        .toggleViewMode(),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 10),
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
                  AmPress(
                    onTap: () => context.push('/crear-recordatorio'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AmColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AmColors.accent.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AmDimens.gapS),
            Expanded(
              child: remindersAsync.when(
                loading: () => const AmLoader(),
                error: (_, __) => Center(
                  child: Text(l10n.remindersError,
                      style: TextStyle(color: cs.tertiary)),
                ),
                data: (_) => ui.viewMode == RemindersViewMode.list
                    ? const ReminderListView()
                    : const ReminderCalendarView(),
              ),
            ),
            const SizedBox(height: AmDimens.gapM),
          ],
        ),
      ),
    );
  }
}
