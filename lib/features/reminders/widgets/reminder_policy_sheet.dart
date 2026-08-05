import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/policy.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_spinner.dart';
import '../../../core/widgets/am_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../clients/providers/clients_provider.dart';

/// Sheet para elegir la póliza asociada a un recordatorio — solo pólizas del
/// cliente ya elegido (policyId es opcional en el backend).
class ReminderPolicySheet extends ConsumerStatefulWidget {
  const ReminderPolicySheet({
    super.key,
    required this.contactId,
    required this.onSelect,
    this.selectedPolicyId,
  });

  final String contactId;
  final String? selectedPolicyId;
  final ValueChanged<Policy?> onSelect;

  @override
  ConsumerState<ReminderPolicySheet> createState() =>
      _ReminderPolicySheetState();
}

class _ReminderPolicySheetState extends ConsumerState<ReminderPolicySheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

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
    final l10n = AppLocalizations.of(context)!;
    final policiesAsync = ref.watch(contactPoliciesProvider(widget.contactId));
    final policies = policiesAsync.asData?.value ?? [];
    final filtered = policies.where((p) => p.matchesQuery(_query)).toList();

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
                  l10n.remindersSelectPolicyTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: AmDimens.gapM),
                AmTextField(
                  controller: _searchCtrl,
                  hint: l10n.clientsSearchPolicyHint,
                  icon: Icons.search,
                ),
              ],
            ),
          ),
          Flexible(
            child: policiesAsync.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AmDimens.gapL),
                    child: SizedBox(
                      height: 80,
                      child: Center(child: AmSpinner()),
                    ),
                  )
                : SingleChildScrollView(
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
                              l10n.remindersNoPolicyOption,
                              style: TextStyle(
                                fontWeight: widget.selectedPolicyId == null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: widget.selectedPolicyId == null
                                    ? cs.primary
                                    : cs.onSurface,
                              ),
                            ),
                            trailing: widget.selectedPolicyId == null
                                ? Icon(Icons.check, color: cs.primary, size: 20)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AmDimens.cardRadius),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onSelect(null);
                            },
                          ),
                          ...filtered.map((p) {
                            final isCurrent = p.id == widget.selectedPolicyId;
                            return ListTile(
                              leading: Icon(Icons.description_outlined,
                                  color: isCurrent ? cs.primary : cs.onSurfaceVariant),
                              title: Text(
                                p.policyNumber ?? '—',
                                style: TextStyle(
                                  fontWeight:
                                      isCurrent ? FontWeight.w600 : FontWeight.normal,
                                  color: isCurrent ? cs.primary : cs.onSurface,
                                ),
                              ),
                              subtitle: p.productName != '—'
                                  ? Text(p.productName,
                                      style: TextStyle(fontSize: 12.5, color: cs.tertiary))
                                  : null,
                              trailing: isCurrent
                                  ? Icon(Icons.check, color: cs.primary, size: 20)
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AmDimens.cardRadius),
                              ),
                              onTap: isCurrent
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      widget.onSelect(p);
                                    },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
          ),
          SafeArea(child: const SizedBox.shrink()),
        ],
      ),
    );
  }
}
