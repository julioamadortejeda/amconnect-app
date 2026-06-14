import 'package:flutter/material.dart';
import '../../../core/models/reminder_comment.dart';
import '../../../core/theme/app_dimensions.dart';

class ReminderCommentBubble extends StatelessWidget {
  const ReminderCommentBubble({super.key, required this.comment});

  final ReminderComment comment;

  static String _fmtDate(DateTime dt) {
    const wd = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const mo = ['ene', 'feb', 'mar', 'abr', 'may', 'jun',
                 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${wd[dt.weekday - 1]} ${dt.day} ${mo[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AmDimens.gapXS),
      padding: const EdgeInsets.all(AmDimens.gapS),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.content,
              style: TextStyle(fontSize: 14, color: cs.onSurface)),
          const SizedBox(height: AmDimens.gapXS),
          Text(_fmtDate(comment.createdAt),
              style: TextStyle(fontSize: 11.5, color: cs.tertiary)),
        ],
      ),
    );
  }
}
