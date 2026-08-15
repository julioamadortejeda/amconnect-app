import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/policy.dart';
import '../../../core/models/reminder.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/am_avatar.dart';
import '../../../core/widgets/am_card.dart';
import '../../../core/widgets/am_ramo_icon.dart';
import '../../../core/widgets/am_select_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../clients/providers/clients_provider.dart';
import '../../home/providers/home_provider.dart';
import '../providers/share_target_provider.dart';
import 'share_destination_row.dart';

/// Lista de destinos posibles para el contenido compartido. Cada fila que
/// necesita un registro concreto (cliente, póliza, recordatorio) abre su
/// selector al tocarla, con la cartera real del asesor.
class ShareDestinationSelector extends ConsumerWidget {
  const ShareDestinationSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(shareTargetProvider);

    // Los selectores necesitan la cartera completa, no solo la primera página
    // que trajo el scroll de las listas.
    final portfolio = ref.watch(ensureFullPortfolioDataProvider);
    final reminders = ref.watch(remindersProvider);
    final portfolioLoading = portfolio.isLoading;

    return AmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shareTargetSubtitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AmDimens.gapM),
          ShareDestinationRow(
            type: ShareDestinationType.policyIngest,
            selectedType: state.destinationType,
            icon: Icons.auto_awesome,
            title: l10n.shareTargetDestinationPolicyIngest,
            hint: state.canIngestAsPolicy
                ? l10n.shareTargetDestinationPolicyIngestSub
                : l10n.shareTargetPolicyIngestUnavailable,
            enabled: state.canIngestAsPolicy,
            onSelect: () => ref
                .read(shareTargetProvider.notifier)
                .setDestinationType(ShareDestinationType.policyIngest),
          ),
          const Divider(height: 1),
          ShareDestinationRow(
            type: ShareDestinationType.global,
            selectedType: state.destinationType,
            icon: Icons.language,
            title: l10n.shareTargetDestinationGlobal,
            onSelect: () => ref
                .read(shareTargetProvider.notifier)
                .setDestinationType(ShareDestinationType.global),
          ),
          const Divider(height: 1),
          ShareDestinationRow(
            type: ShareDestinationType.client,
            selectedType: state.destinationType,
            icon: Icons.person_outline,
            title: l10n.shareTargetDestinationClient,
            value: state.selectedClientName,
            actionLabel: l10n.shareTargetSelectClient,
            loading: portfolioLoading,
            onSelect: () => _selectOrPick(
              ref,
              ShareDestinationType.client,
              portfolioLoading,
              () => _pickClient(context, ref),
            ),
            onAction: () => _pickClient(context, ref),
          ),
          const Divider(height: 1),
          ShareDestinationRow(
            type: ShareDestinationType.policy,
            selectedType: state.destinationType,
            icon: Icons.description_outlined,
            title: l10n.shareTargetDestinationPolicy,
            value: state.selectedPolicyNumber,
            actionLabel: l10n.shareTargetSelectPolicy,
            loading: portfolioLoading,
            onSelect: () => _selectOrPick(
              ref,
              ShareDestinationType.policy,
              portfolioLoading,
              () => _pickPolicy(context, ref),
            ),
            onAction: () => _pickPolicy(context, ref),
          ),
          const Divider(height: 1),
          ShareDestinationRow(
            type: ShareDestinationType.reminder,
            selectedType: state.destinationType,
            icon: Icons.access_time,
            title: l10n.shareTargetDestinationReminder,
            value: state.selectedReminderTitle,
            actionLabel: l10n.shareTargetSelectReminder,
            loading: reminders.isLoading,
            onSelect: () => _selectOrPick(
              ref,
              ShareDestinationType.reminder,
              reminders.isLoading,
              () => _pickReminder(context, ref),
            ),
            onAction: () => _pickReminder(context, ref),
          ),
        ],
      ),
    );
  }

  /// Tocar la fila marca el destino y abre su selector de una vez. Si la
  /// cartera aún está cargando solo marca el destino — el sheet se abriría
  /// vacío.
  void _selectOrPick(
    WidgetRef ref,
    ShareDestinationType type,
    bool loading,
    VoidCallback pick,
  ) {
    if (loading) {
      ref.read(shareTargetProvider.notifier).setDestinationType(type);
      return;
    }
    pick();
  }

  void _pickClient(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(shareTargetProvider.notifier);
    final clients = ref.read(clientsProvider).asData?.value ?? const <Contact>[];

    notifier.setDestinationType(ShareDestinationType.client);
    _showSelectSheet<Contact>(
      context: context,
      title: l10n.shareTargetSelectClient,
      searchHint: l10n.clientsSearchHint,
      items: clients,
      itemId: (c) => c.id,
      itemLabel: (c) => c.fullName,
      itemFilter: (c, q) => c.matchesQuery(q),
      selectedId: ref.read(shareTargetProvider).selectedClientId,
      itemLeading: (_, c) => AmAvatar(initials: c.initials, color: c.color, size: 34, radius: 11),
      onSelect: (c) {
        if (c != null) notifier.selectClient(id: c.id, name: c.fullName);
      },
    );
  }

  void _pickPolicy(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(shareTargetProvider.notifier);
    final policies = ref.read(policiesProvider).asData?.value ?? const <Policy>[];

    notifier.setDestinationType(ShareDestinationType.policy);
    _showSelectSheet<Policy>(
      context: context,
      title: l10n.shareTargetSelectPolicy,
      searchHint: l10n.clientsSearchPolicyHint,
      items: policies,
      itemId: (p) => p.id,
      itemLabel: (p) => _policyLabel(p, l10n),
      itemFilter: (p, q) => p.matchesQuery(q),
      selectedId: ref.read(shareTargetProvider).selectedPolicyId,
      itemLeading: (_, p) => AmRamoIcon(ramo: p.branchName, size: 34),
      onSelect: (p) {
        if (p != null) notifier.selectPolicy(id: p.id, number: _policyLabel(p, l10n));
      },
    );
  }

  void _pickReminder(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(shareTargetProvider.notifier);
    final all = ref.read(remindersProvider).asData?.value ?? const <Reminder>[];
    final active = all.where((r) => r.isActive).toList();

    notifier.setDestinationType(ShareDestinationType.reminder);
    _showSelectSheet<Reminder>(
      context: context,
      title: l10n.shareTargetSelectReminder,
      searchHint: l10n.shareTargetSearchReminderHint,
      items: active,
      itemId: (r) => r.id,
      itemLabel: (r) => r.title,
      itemFilter: (r, q) {
        if (q.isEmpty) return true;
        final lower = q.toLowerCase();
        return r.title.toLowerCase().contains(lower) ||
            (r.contactName?.toLowerCase().contains(lower) ?? false);
      },
      selectedId: ref.read(shareTargetProvider).selectedReminderId,
      itemLeading: (ctx, r) => _ReminderDateChip(reminder: r),
      onSelect: (r) {
        if (r != null) notifier.selectReminder(id: r.id, title: r.title);
      },
    );
  }

  static String _policyLabel(Policy policy, AppLocalizations l10n) {
    final number = policy.policyNumber?.trim();
    final base = (number == null || number.isEmpty) ? l10n.shareTargetPolicyNoNumber : number;
    final holder = policy.contactName;
    return (holder == null || holder.isEmpty) ? base : '$base · $holder';
  }

  static void _showSelectSheet<T>({
    required BuildContext context,
    required String title,
    required String searchHint,
    required List<T> items,
    required String Function(T) itemId,
    required String Function(T) itemLabel,
    required bool Function(T, String) itemFilter,
    required ValueChanged<T?> onSelect,
    String? selectedId,
    Widget? Function(BuildContext, T)? itemLeading,
  }) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AmSelectSheet<T>(
        title: title,
        searchHint: searchHint,
        items: items,
        itemId: itemId,
        itemLabel: itemLabel,
        itemFilter: itemFilter,
        selectedId: selectedId,
        itemLeading: itemLeading,
        onSelect: onSelect,
      ),
    );
  }
}

/// Fecha compacta del recordatorio, como leading en el selector.
class _ReminderDateChip extends StatelessWidget {
  const _ReminderDateChip({required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        fmtSmartDate(reminder.dueDate, l10n),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
