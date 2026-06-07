import 'package:flutter/material.dart';
import 'package:amconnect/core/theme/am_theme.dart';

enum AmBadgeTone { accent, green, red, amber, muted }

class AmBadge extends StatelessWidget {
  const AmBadge({super.key, required this.label, this.tone = AmBadgeTone.muted, this.icon});

  final String label;
  final AmBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final (bg, fg) = switch (tone) {
      AmBadgeTone.accent => (cs.primaryContainer, cs.onPrimaryContainer),
      AmBadgeTone.green  => (am.greenWash, am.green),
      AmBadgeTone.red    => (cs.errorContainer, cs.error),
      AmBadgeTone.amber  => (am.amberWash, am.amber),
      AmBadgeTone.muted  => (cs.secondaryContainer, cs.tertiary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: fg,
                letterSpacing: 0.01,
              )),
        ],
      ),
    );
  }
}
