import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/reminder.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_calendar.dart';
import '../../../core/widgets/am_card.dart';
import '../providers/reminders_provider.dart';
import 'reminder_item.dart';
import '../../../core/widgets/am_stagger.dart';
import '../../../l10n/app_localizations.dart';

const _kAmber = Color(0xFFD97706);

List<Color> _priorityDots(List<Reminder> reminders, ColorScheme cs) {
  final dots = <Color>[];
  if (reminders.any((r) => r.priority == ReminderPriority.urgent)) {
    dots.add(cs.error);
  }
  if (reminders.any((r) => r.priority == ReminderPriority.warning)) {
    dots.add(_kAmber);
  }
  if (reminders.any((r) => r.priority == ReminderPriority.normal)) {
    dots.add(cs.primary);
  }
  return dots;
}

class ReminderCalendarView extends ConsumerStatefulWidget {
  const ReminderCalendarView({super.key});

  @override
  ConsumerState<ReminderCalendarView> createState() =>
      _ReminderCalendarViewState();
}

class _ReminderCalendarViewState extends ConsumerState<ReminderCalendarView> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() => setState(() {
        _visibleMonth =
            DateTime(_visibleMonth.year, _visibleMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _visibleMonth =
            DateTime(_visibleMonth.year, _visibleMonth.month + 1);
      });

  void _goToToday() {
    final today = DateTime.now();
    setState(() => _visibleMonth = DateTime(today.year, today.month));
    ref.read(remindersUiProvider.notifier).selectDate(
          DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ui = ref.watch(remindersUiProvider);
    final byDate = ref.watch(remindersByDateProvider);
    final dayReminders = ref.watch(selectedDayRemindersProvider);

    final events = {
      for (final e in byDate.entries)
        e.key: _priorityDots(e.value, cs),
    };

    return SingleChildScrollView(
      child: Column(
        children: [
          AmAnimateIn(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
              child: AmCalendar(
                visibleMonth: _visibleMonth,
                selectedDate: ui.selectedDate,
                events: events,
                onDaySelected: (d) =>
                    ref.read(remindersUiProvider.notifier).selectDate(d),
                onPrevMonth: _prevMonth,
                onNextMonth: _nextMonth,
                onToday: _goToToday,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (ui.selectedDate != null)
            AmAnimateIn(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
                child: _DayHeader(date: ui.selectedDate!, l10n: l10n),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
            child: dayReminders.isEmpty
                ? AmAnimateIn(
                    index: 2,
                    child: Text(
                      l10n.remindersEmpty,
                      style: TextStyle(fontSize: 14, color: cs.tertiary),
                    ),
                  )
                : AmAnimateIn(
                    index: 2,
                    child: AmCard(
                      noPad: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < dayReminders.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 0,
                                indent: AmDimens.screenH,
                                endIndent: AmDimens.screenH,
                                color: cs.outlineVariant,
                              ),
                            ReminderItem(reminder: dayReminders[i]),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.l10n});
  final DateTime date;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date == today;

    final weekDay = DateFormat('EEEE', 'es').format(date);
    final dayNum = DateFormat('d', 'es').format(date);
    final month = DateFormat('MMMM', 'es').format(date);

    final label = '${weekDay[0].toUpperCase()}${weekDay.substring(1)} $dayNum · '
        '${month[0].toUpperCase()}${month.substring(1)}'
        '${isToday ? ' · ${l10n.calendarToday.toUpperCase()}' : ''}';

    return Text(
      label,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.tertiary,
          letterSpacing: 0.3),
    );
  }
}
