import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/agent_note.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_note_row.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/reminders_provider.dart';

/// Notas ligadas a este recordatorio — hoy solo se crean desde el Share
/// Target (compartir un archivo/texto desde otra app y asignarlo a un
/// recordatorio). Misma presentación que las notas de cliente/póliza
/// (`AmNoteRow`), solo lectura: no hay composer aquí.
class ReminderNotesSection extends ConsumerWidget {
  const ReminderNotesSection({super.key, required this.reminderId});

  final String reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    ref.watch(reminderNotesRealtimeProvider(reminderId));
    final notesAsync = ref.watch(reminderNotesProvider(reminderId));
    final notes = notesAsync.asData?.value ?? const <AgentNote>[];

    if (notesAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: AmLoader(),
      );
    }

    if (notes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          l10n.remindersDetailNoAttachments,
          style: TextStyle(fontSize: 14, color: cs.tertiary),
        ),
      );
    }

    return Column(
      children: [
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: AmDimens.gapS),
            child: AmNoteRow(note: note),
          ),
      ],
    );
  }
}
