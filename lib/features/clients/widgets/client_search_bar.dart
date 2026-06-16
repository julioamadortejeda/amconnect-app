import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class ClientSearchBar extends StatelessWidget {
  const ClientSearchBar({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 22,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: cs.onSurfaceVariant, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: l10n.clientsSearchHint,
                hintStyle: TextStyle(color: cs.tertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
