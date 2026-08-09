import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class ClientSearchBar extends StatelessWidget {
  const ClientSearchBar({super.key, required this.onChanged, this.hintText});

  final ValueChanged<String> onChanged;
  final String? hintText;

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
            color: AmColors.shadowSoft,
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
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: hintText ?? l10n.clientsSearchHint,
                hintStyle: TextStyle(color: cs.tertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
