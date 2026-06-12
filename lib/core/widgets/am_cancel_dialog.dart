import 'package:flutter/material.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/l10n/app_localizations.dart';
import 'package:amconnect/core/theme/app_dimensions.dart';

class AmCancelDialog extends StatefulWidget {
  const AmCancelDialog({
    super.key,
    required this.title,
    required this.onConfirm,
  });

  final String title;
  final void Function(String comment) onConfirm;

  @override
  State<AmCancelDialog> createState() => _AmCancelDialogState();
}

class _AmCancelDialogState extends State<AmCancelDialog> {
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
    Navigator.pop(context);
    widget.onConfirm(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH * 1.5),
      child: AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets,
        duration: const Duration(milliseconds: 100),
        curve: Curves.decelerate,
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
                    color: cs.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: cs.error,
                    size: 34,
                  ),
                ),
                const SizedBox(height: AmDimens.cardPad),
                // Title
                Text(
                  l10n.remindersCancelTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    letterSpacing: -0.01,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AmDimens.gapXS),
                // Description/Sub
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.tertiary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AmDimens.gapM),
                // Comment input box
                Container(
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(AmDimens.gapS),
                    border: Border.all(
                      color: _showError
                          ? cs.error
                          : cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: TextField(
                    controller: _ctrl,
                    maxLines: 3,
                    minLines: 2,
                    autofocus: true,
                    style: TextStyle(fontSize: 15, color: cs.onSurface),
                    onChanged: (_) {
                      if (_showError) setState(() => _showError = false);
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: l10n.remindersCancelHint,
                      hintStyle: TextStyle(color: cs.tertiary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_showError) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.remindersActionCommentRequired,
                      style: TextStyle(fontSize: 12, color: cs.error),
                    ),
                  ),
                ],
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
                        onTap: _confirm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AmDimens.gapS),
                          decoration: BoxDecoration(
                            color: cs.error,
                            borderRadius: BorderRadius.circular(AmDimens.gapS),
                            boxShadow: [
                              BoxShadow(
                                color: cs.error.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            l10n.remindersCancelConfirmBtn,
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
      ),
    );
  }
}
