import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';
import 'am_press.dart';
import 'am_text_field.dart';

class AmSelectSheet<T> extends StatefulWidget {
  const AmSelectSheet({
    super.key,
    required this.title,
    required this.items,
    required this.itemLabel,
    required this.itemFilter,
    required this.onSelect,
    this.itemId,
    this.selectedId,
    this.searchHint = 'Buscar...',
    this.itemLeading,
    this.createNewLabel,
    this.onCreateNew,
  });

  final String title;
  final List<T> items;
  final String Function(T) itemLabel;
  final bool Function(T, String query) itemFilter;
  final String Function(T)? itemId;
  final String? selectedId;
  final ValueChanged<T?> onSelect;
  final String searchHint;
  final Widget? Function(BuildContext, T)? itemLeading;
  final String? createNewLabel;
  final Future<T?> Function(String query)? onCreateNew;

  @override
  State<AmSelectSheet<T>> createState() => _AmSelectSheetState<T>();
}

class _AmSelectSheetState<T> extends State<AmSelectSheet<T>> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onQueryChanged);
  }

  void _onQueryChanged() => setState(() => _query = _searchCtrl.text);

  @override
  void dispose() {
    _searchCtrl.removeListener(_onQueryChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = widget.items.where((item) => widget.itemFilter(item, _query)).toList();

    final showCreateButton = widget.onCreateNew != null &&
        widget.createNewLabel != null &&
        _query.trim().isNotEmpty &&
        !filtered.any((item) => widget.itemLabel(item).toLowerCase() == _query.trim().toLowerCase());

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AmDimens.gapM,
                AmDimens.gapXS,
                AmDimens.gapM,
                0,
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AmDimens.gapM),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: AmDimens.gapM),
                  AmTextField(
                    controller: _searchCtrl,
                    hint: widget.searchHint,
                    icon: Icons.search,
                  ),
                  const SizedBox(height: AmDimens.gapS),
                ],
              ),
            ),
            if (_isCreating)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AmDimens.gapL),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              if (showCreateButton)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AmDimens.gapM, vertical: AmDimens.gapXS),
                  child: AmPress(
                    onTap: () async {
                      final name = _query.trim();
                      setState(() => _isCreating = true);
                      try {
                        final navigator = Navigator.of(context);
                        final newItem = await widget.onCreateNew!(name);
                        if (newItem != null && mounted) {
                          widget.onSelect(newItem);
                          navigator.pop(newItem);
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isCreating = false);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline, color: cs.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${widget.createNewLabel} "$_query"',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AmDimens.gapM, vertical: AmDimens.gapXS),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final label = widget.itemLabel(item);
                    final id = widget.itemId?.call(item) ?? '';
                    final isSelected = widget.selectedId != null && id == widget.selectedId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: AmPress(
                        onTap: () {
                          widget.onSelect(item);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? cs.primary.withValues(alpha: 0.08) : cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? cs.primary.withValues(alpha: 0.2) : cs.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (widget.itemLeading != null) ...[
                                widget.itemLeading!(context, item) ?? const SizedBox.shrink(),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? cs.primary : cs.onSurface,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: cs.primary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AmDimens.gapM),
            ]
          ],
        ),
      ),
    );
  }
}
