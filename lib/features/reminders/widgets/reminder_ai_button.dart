import 'package:flutter/material.dart';
import '../../../core/models/agent_note.dart';
import '../../../core/models/reminder.dart';
import '../../../core/widgets/am_ai_ask_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/data/chat_context.dart';

class ReminderAiButton extends StatelessWidget {
  const ReminderAiButton({super.key, required this.reminder, this.notes});

  final Reminder reminder;
  final List<AgentNote>? notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmAiAskButton(
      label: l10n.remindersAskAbout,
      aiContext: AiChatContext.fromReminder(reminder, notes: notes),
    );
  }
}
