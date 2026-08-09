import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/am_press.dart';
import '../../../l10n/app_localizations.dart';

/// Bottom sheet para agregar una nota rápida a un cliente. Devuelve el texto
/// escrito, o null si se cancela.
class AddClientNoteSheet extends StatefulWidget {
  const AddClientNoteSheet({super.key});

  static Future<String?> show(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddClientNoteSheet(),
    );
  }

  @override
  State<AddClientNoteSheet> createState() => _AddClientNoteSheetState();
}

class _AddClientNoteSheetState extends State<AddClientNoteSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.clientsAddNote,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 14.5, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: l10n.clientsAddNoteHint,
                filled: true,
                fillColor: cs.secondaryContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _ctrl,
              builder: (context, value, _) {
                final canSave = value.text.trim().isNotEmpty;
                return AmPress(
                  onTap: canSave
                      ? () => Navigator.of(context).pop(value.text.trim())
                      : null,
                  child: Opacity(
                    opacity: canSave ? 1.0 : 0.5,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AmColors.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        l10n.clientsAddNote,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
