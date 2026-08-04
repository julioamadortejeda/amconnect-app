import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/knowledge_dashboard_provider.dart';

/// Barra de búsqueda con debounce del dashboard de conocimiento.
class KnowledgeSearchBar extends ConsumerStatefulWidget {
  const KnowledgeSearchBar({super.key});

  @override
  ConsumerState<KnowledgeSearchBar> createState() => _KnowledgeSearchBarState();
}

class _KnowledgeSearchBarState extends ConsumerState<KnowledgeSearchBar> {
  final _ctrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String val) {
    setState(() {});
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(knowledgeSearchQueryProvider.notifier).updateQuery(val);
    });
  }

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
              controller: _ctrl,
              onChanged: _onChanged,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: l10n.feedSearchHint,
                hintStyle: TextStyle(color: cs.tertiary),
              ),
            ),
          ),
          if (_ctrl.text.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _ctrl.clear();
                ref.read(knowledgeSearchQueryProvider.notifier).updateQuery('');
                setState(() {});
              },
              child: Icon(Icons.close, color: cs.tertiary, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
