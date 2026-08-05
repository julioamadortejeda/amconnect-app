import 'package:flutter/material.dart';
import '../../../core/widgets/am_card.dart';
import '../data/feed_input_type.dart';

/// Tarjeta de una opción de ingesta en el grid del Feed.
class FeedTypeCard extends StatelessWidget {
  const FeedTypeCard({super.key, required this.t, this.compact = false});

  final FeedInputType t;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Color.alphaBlend(t.color.withValues(alpha: 0.14), Colors.white);
    final iconSize = compact ? 34.0 : 40.0;
    final iconInner = compact ? 18.0 : 22.0;
    final iconRadius = compact ? 10.0 : 13.0;

    return AmCard(
      onTap: t.onTap,
      padding: compact ? const EdgeInsets.all(12) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(iconRadius)),
            child: Icon(t.icon, size: iconInner, color: t.color),
          ),
          SizedBox(height: compact ? 7 : 10),
          Text(t.label,
              style: TextStyle(
                  fontSize: compact ? 13.0 : 15.0,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 3),
          Flexible(
            child: Text(t.sub,
                style: TextStyle(
                    fontSize: compact ? 11.0 : 12.0,
                    color: cs.tertiary,
                    height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
