import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/contact.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_avatar.dart';
import '../../../core/widgets/am_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../clients/providers/clients_provider.dart';

/// Sheet para elegir el cliente asociado a un recordatorio — con búsqueda y
/// opción de dejarlo sin cliente (contactId es opcional en el backend).
class ReminderClientSheet extends ConsumerStatefulWidget {
  const ReminderClientSheet({
    super.key,
    required this.onSelect,
    this.selectedClientId,
  });

  final String? selectedClientId;
  final ValueChanged<Contact?> onSelect;

  @override
  ConsumerState<ReminderClientSheet> createState() =>
      _ReminderClientSheetState();
}

class _ReminderClientSheetState extends ConsumerState<ReminderClientSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onQueryChanged);
    // El selector necesita la cartera completa, no solo la primera página.
    Future.microtask(() => ref.read(clientsProvider.notifier).loadAll());
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
    final l10n = AppLocalizations.of(context)!;
    final clients = ref.watch(clientsProvider).asData?.value ?? [];
    final filtered = clients.where((c) => c.matchesQuery(_query)).toList();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                  l10n.remindersSelectClientTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: AmDimens.gapM),
                AmTextField(
                  controller: _searchCtrl,
                  hint: l10n.clientsSearchHint,
                  icon: Icons.search,
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AmDimens.gapM,
                  AmDimens.gapS,
                  AmDimens.gapM,
                  AmDimens.gapM,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.block, color: cs.onSurfaceVariant),
                      title: Text(
                        l10n.remindersNoClientOption,
                        style: TextStyle(
                          fontWeight: widget.selectedClientId == null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: widget.selectedClientId == null
                              ? cs.primary
                              : cs.onSurface,
                        ),
                      ),
                      trailing: widget.selectedClientId == null
                          ? Icon(Icons.check, color: cs.primary, size: 20)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelect(null);
                      },
                    ),
                    ...filtered.map((c) {
                      final isCurrent = c.id == widget.selectedClientId;
                      return ListTile(
                        leading: AmAvatar(
                          initials: c.initials,
                          color: c.color,
                          size: 36,
                          radius: 11,
                        ),
                        title: Text(
                          c.fullName,
                          style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.normal,
                            color: isCurrent ? cs.primary : cs.onSurface,
                          ),
                        ),
                        trailing: isCurrent
                            ? Icon(Icons.check, color: cs.primary, size: 20)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AmDimens.cardRadius),
                        ),
                        onTap: isCurrent
                            ? null
                            : () {
                                Navigator.pop(context);
                                widget.onSelect(c);
                              },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          const SafeArea(child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
