import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'am_press.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_dimensions.dart';

class AmRescheduleDialog extends StatefulWidget {
  const AmRescheduleDialog({
    super.key,
    required this.initialDateTime,
    required this.onConfirm,
  });

  final DateTime initialDateTime;
  final void Function(DateTime newDateTime) onConfirm;

  @override
  State<AmRescheduleDialog> createState() => _AmRescheduleDialogState();
}

class _AmRescheduleDialogState extends State<AmRescheduleDialog> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
  }

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Hoy';
    if (d == today.add(const Duration(days: 1))) return 'Mañana';
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date != null) {
      setState(() {
        _selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  void _selectTime() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        final cs = Theme.of(context).colorScheme;
        final l10n = AppLocalizations.of(context)!;
        return Container(
          height: 280,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: cs.surface,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: Text(
                        l10n.remindersConfirmCancelBtn,
                        style: TextStyle(color: cs.tertiary),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: Text(
                        l10n.feedSuccessDone,
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: Theme.of(context).brightness,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          color: cs.onSurface,
                          fontSize: 21,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: _selectedDateTime,
                      use24hFormat: true,
                      onDateTimeChanged: (DateTime newDateTime) {
                        setState(() {
                          _selectedDateTime = DateTime(
                            _selectedDateTime.year,
                            _selectedDateTime.month,
                            _selectedDateTime.day,
                            newDateTime.hour,
                            newDateTime.minute,
                          );
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH * 1.5),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.85, end: 1.0),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: ((scale - 0.85) / 0.15).clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AmDimens.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AmDimens.cardPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Styled Circular Icon Header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: cs.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: AmDimens.cardPad),
              // Title
              Text(
                l10n.remindersRescheduleTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                  letterSpacing: -0.01,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AmDimens.gapXS),
              Text(
                l10n.remindersRescheduleMessage,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.tertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AmDimens.gapL),
              // Date Field Card
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(AmDimens.gapS),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 18, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.remindersFieldDateUpper,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: cs.tertiary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(_selectedDateTime),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 20, color: cs.tertiary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AmDimens.gapS),
              // Time Field Card
              GestureDetector(
                onTap: _selectTime,
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(AmDimens.gapS),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 18, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.remindersFieldTimeUpper,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: cs.tertiary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(_selectedDateTime),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 20, color: cs.tertiary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AmDimens.gapL),
              // Actions Row
              Row(
                children: [
                  Expanded(
                    child: AmPress(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: AmDimens.gapS),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(AmDimens.gapS),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          l10n.remindersConfirmCancelBtn,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AmPress(
                      onTap: () {
                        Navigator.pop(context);
                        widget.onConfirm(_selectedDateTime);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: AmDimens.gapS),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(AmDimens.gapS),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          l10n.remindersRescheduleSave,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
