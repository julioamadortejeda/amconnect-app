import 'package:flutter/material.dart';
import '../../../core/models/reminder.dart';
import '../../../core/widgets/am_ai_ask_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/data/chat_context.dart';

class ReminderAiButton extends StatelessWidget {
  const ReminderAiButton({super.key, required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmAiAskButton(
      label: l10n.remindersAskAbout(reminder.title),
      aiContext: AiChatContext.fromReminder(reminder),
    );
  }
}
