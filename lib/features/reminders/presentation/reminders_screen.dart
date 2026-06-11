import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/theme/app_dimensions.dart';
import 'package:amconnect/core/theme/am_theme.dart';
import 'package:amconnect/core/models/reminder.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/features/home/providers/home_provider.dart';
import 'package:amconnect/l10n/app_localizations.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  String _filter = 'todos';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final remindersAsync = ref.watch(remindersProvider);
    final filter = _filter;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AmDimens.screenH, 12, AmDimens.screenH, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.remindersPendingCount(
                              (remindersAsync.asData?.value ?? [])
                                  .where((r) => !r.hecho)
                                  .length),
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: cs.tertiary),
                        ),
                        Text(l10n.remindersTitle,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                                letterSpacing: -0.01)),
                      ],
                    ),
                  ),
                  AmPress(
                    onTap: () => context.push('/crear-recordatorio'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AmColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AmColors.accent.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AmDimens.gapS),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
                children: [
                  for (final (key, label) in [
                    ('todos', l10n.remindersFilterAll),
                    ('PAYMENT', l10n.remindersFilterPayments),
                    ('RENEWAL', l10n.remindersFilterRenewals),
                    ('CALL', l10n.remindersFilterCalls),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: label,
                        active: filter == key,
                        onTap: () => setState(() => _filter = key),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AmDimens.gapS),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
                child: remindersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: Text('Error al cargar recordatorios',
                        style: TextStyle(color: cs.tertiary)),
                  ),
                  data: (reminders) {
                    final filtered = reminders.where((r) {
                      if (filter == 'todos') return true;
                      return r.tipo == filter;
                    }).toList();
                    return AmCard(
                      noPad: true,
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(
                            height: 0,
                            indent: AmDimens.screenH,
                            endIndent: AmDimens.screenH,
                            color: cs.outlineVariant),
                        itemBuilder: (_, i) => _ReminderItem(r: filtered[i]),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AmDimens.gapM),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AmPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AmColors.accent : cs.surface,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: active
                  ? AmColors.accent.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.055),
              blurRadius: active ? 12 : 8,
            ),
          ],
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : cs.onSurfaceVariant)),
      ),
    );
  }
}

class _ReminderItem extends ConsumerWidget {
  const _ReminderItem({required this.r});
  final Reminder r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final icon = switch (r.tipo) {
      'PAYMENT'      => Icons.payments_outlined,
      'RENEWAL'      => Icons.autorenew,
      'CANCELLATION' => Icons.block,
      'FOLLOW_UP'    => Icons.flag_outlined,
      'CALL'         => Icons.phone_outlined,
      'APPOINTMENT'  => Icons.event_outlined,
      'ANNIVERSARY'  => Icons.cake,
      _              => Icons.notifications_outlined,
    };
    final (iconFg, iconBg) = switch (r.priority) {
      ReminderPriority.urgent  => (cs.error, cs.errorContainer),
      ReminderPriority.warning => (am.amber, am.amberWash),
      ReminderPriority.normal  => (cs.primary, cs.primaryContainer),
    };

    return Opacity(
      opacity: r.hecho ? 0.55 : 1.0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AmDimens.screenH, AmDimens.gapS, AmDimens.screenH, AmDimens.gapS),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => ref.read(remindersProvider.notifier).toggle(r.id),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: r.hecho ? am.green : Colors.transparent,
                  border: r.hecho ? null : Border.all(color: cs.outline, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: r.hecho
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 18, color: iconFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (r.contactId != null) context.push('/clientes/${r.contactId}');
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.titulo,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                            decoration: r.hecho ? TextDecoration.lineThrough : null)),
                    Text(
                        r.hora != '—' ? '${r.sub} · ${r.hora}' : r.sub,
                        style: TextStyle(fontSize: 12.5, color: cs.tertiary)),
                  ],
                ),
              ),
            ),
            if (!r.hecho && r.priority != ReminderPriority.normal)
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: r.priority == ReminderPriority.urgent
                        ? cs.error
                        : am.amber,
                    shape: BoxShape.circle,
                  )),
          ],
        ),
      ),
    );
  }
}
