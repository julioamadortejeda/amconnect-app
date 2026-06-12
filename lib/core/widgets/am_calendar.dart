import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/l10n/app_localizations.dart';

/// Calendario mensual genérico.
///
/// [events] — mapa de fecha → lista de colores de puntos a mostrar ese día.
///            El caller decide cuántos puntos y de qué color; este widget solo los pinta.
/// [selectedDate] — día actualmente seleccionado.
/// [onDaySelected] — callback al tocar un día.
/// [visibleMonth] — mes que se muestra (primer día del mes).
/// [onPrevMonth] / [onNextMonth] / [onToday] — navegación.
class AmCalendar extends StatelessWidget {
  const AmCalendar({
    super.key,
    required this.visibleMonth,
    required this.selectedDate,
    required this.events,
    required this.onDaySelected,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onToday,
  });

  final DateTime visibleMonth;
  final DateTime? selectedDate;
  final Map<DateTime, List<Color>> events;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AmCard(
      child: Column(
        children: [
          _CalendarHeader(
            month: visibleMonth,
            onPrev: onPrevMonth,
            onNext: onNextMonth,
            onToday: onToday,
            l10n: l10n,
          ),
          const SizedBox(height: 12),
          _WeekDayLabels(l10n: l10n),
          const SizedBox(height: 6),
          _CalendarGrid(
            month: visibleMonth,
            selected: selectedDate,
            events: events,
            onSelect: onDaySelected,
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.l10n,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = DateFormat('MMMM yyyy', 'es').format(month);

    return Row(
      children: [
        Text(
          label[0].toUpperCase() + label.substring(1),
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        const Spacer(),
        AmPress(
          onTap: onToday,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: AmColors.accent, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.calendarToday,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AmColors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AmPress(
          onTap: onPrev,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.chevron_left, size: 18, color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 6),
        AmPress(
          onTap: onNext,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _WeekDayLabels extends StatelessWidget {
  const _WeekDayLabels({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labels = [
      l10n.calendarSun, l10n.calendarMon, l10n.calendarTue,
      l10n.calendarWed, l10n.calendarThu, l10n.calendarFri, l10n.calendarSat,
    ];
    return Row(
      children: labels.map((d) => Expanded(
        child: Center(
          child: Text(d,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: cs.tertiary)),
        ),
      )).toList(),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.selected,
    required this.events,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime? selected;
  final Map<DateTime, List<Color>> events;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final startOffset = firstDay.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final rows = ((startOffset + daysInMonth) / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final index = row * 7 + col;
            final dayNum = index - startOffset + 1;

            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }

            final date = DateTime(month.year, month.month, dayNum);
            return Expanded(
              child: _DayCell(
                day: dayNum,
                isToday: date == todayKey,
                isSelected: selected != null && date == selected,
                dotColors: events[date] ?? [],
                onTap: () => onSelect(date),
              ),
            );
          }),
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.dotColors,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final List<Color> dotColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color? bgColor;
    Color textColor = cs.onSurface;

    if (isSelected) {
      bgColor = AmColors.accent;
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = cs.primaryContainer;
      textColor = cs.primary;
    }

    return AmPress(
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: bgColor != null
                  ? BoxDecoration(color: bgColor, shape: BoxShape.circle)
                  : null,
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
            ),
            if (dotColors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: dotColors.map((color) => Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  )).toList(),
                ),
              )
            else
              const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}
