import 'package:flutter/material.dart';
import 'package:amconnect/core/theme/app_dimensions.dart';
import 'package:amconnect/l10n/app_localizations.dart';

class ReminderCommentSheet extends StatefulWidget {
  const ReminderCommentSheet({
    super.key,
    required this.title,
    required this.onConfirm,
  });

  final String title;
  final void Function(String comment) onConfirm;

  @override
  State<ReminderCommentSheet> createState() => _ReminderCommentSheetState();
}

class _ReminderCommentSheetState extends State<ReminderCommentSheet> {
  final _ctrl = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_ctrl.text.trim().isEmpty) {
      setState(() => _showError = true);
      return;
    }
    widget.onConfirm(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AmDimens.screenH,
        12,
        AmDimens.screenH,
        AmDimens.screenH + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.remindersActionCancelTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.title,
            style: TextStyle(fontSize: 13, color: cs.tertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: _showError ? cs.error : cs.outline,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: _ctrl,
              maxLines: 4,
              minLines: 2,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              onChanged: (_) {
                if (_showError) setState(() => _showError = false);
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: l10n.remindersActionCancelHint,
                hintStyle: TextStyle(color: cs.tertiary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_showError) ...[
            const SizedBox(height: 6),
            Text(
              l10n.remindersActionCommentRequired,
              style: TextStyle(fontSize: 12, color: cs.error),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l10n.remindersActionCancelBtn),
            ),
          ),
        ],
      ),
    );
  }
}
