import 'package:flutter/material.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../../../l10n/app_localizations.dart';

/// Sheet para elegir el estado inicial de un recordatorio nuevo — mismos
/// códigos que maneja `AmReminderActionsSheet` para uno ya existente.
class ReminderStatusSelectionSheet extends StatelessWidget {
  const ReminderStatusSelectionSheet({
    super.key,
    required this.selectedCode,
    required this.onSelect,
  });

  final String selectedCode;
  final ValueChanged<String> onSelect;

  static const _codes = ['CREATED', 'IN_PROGRESS', 'PAUSED', 'DONE', 'CANCELLED'];

  IconData _iconFor(String code) => switch (code) {
        'DONE' => Icons.check_circle_outline,
        'IN_PROGRESS' => Icons.access_time_filled_rounded,
        'PAUSED' => Icons.pause_circle_outline,
        'CANCELLED' => Icons.cancel_outlined,
        _ => Icons.radio_button_unchecked,
      };

  Color _colorFor(BuildContext context, String code) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    return switch (code) {
      'DONE' => am.green,
      'IN_PROGRESS' => am.amber,
      'CANCELLED' => cs.error,
      'PAUSED' => cs.tertiary,
      _ => cs.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
                  l10n.remindersSelectStatusTitle,
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
                  children: _codes.map((code) {
                    final isCurrent = code == selectedCode;
                    final color = _colorFor(context, code);
                    return ListTile(
                      leading: Icon(_iconFor(code), color: isCurrent ? cs.primary : color),
                      title: Text(
                        l10n.reminderStatus(code),
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
                              onSelect(code);
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
