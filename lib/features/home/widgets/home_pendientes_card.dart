import 'package:flutter/material.dart';
import 'package:amconnect/core/models/reminder.dart';
import 'package:amconnect/core/theme/app_dimensions.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/features/reminders/widgets/reminder_item.dart';

class HomePendientesCard extends StatelessWidget {
  const HomePendientesCard({super.key, required this.reminders});
  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AmCard(
      noPad: true,
      child: Column(
        children: [
          for (int i = 0; i < reminders.length; i++) ...[
            if (i > 0)
              Divider(
                height: 0,
                indent: AmDimens.screenH,
                endIndent: AmDimens.screenH,
                color: cs.outlineVariant,
              ),
            ReminderItem(reminder: reminders[i]),
          ],
        ],
      ),
    );
  }
}
