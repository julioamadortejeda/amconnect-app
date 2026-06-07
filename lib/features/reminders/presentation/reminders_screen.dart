import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/mock/mock_data.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/features/home/presentation/home_screen.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final reminders = ref.watch(remindersProvider);
    final filter = _filter;
    final filtered = reminders.where((r) {
      if (filter == 'todos') return true;
      return r.tipo == filter;
    }).toList();
    final pending = reminders.where((r) => !r.hecho).length;

    return Scaffold(
      backgroundColor: AmColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.remindersPendingCount(pending),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500,
                                color: AmColors.mutedLight)),
                        Text(l10n.remindersTitle,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                                color: AmColors.inkLight, letterSpacing: -0.01)),
                      ],
                    ),
                  ),
                  AmPress(
                    onTap: () => context.push('/crear-recordatorio'),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AmColors.accent, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AmColors.accent.withValues(alpha: 0.3),
                            blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  for (final (key, label) in [
                    ('todos', l10n.remindersFilterAll),
                    ('pago', l10n.remindersFilterPayments),
                    ('renovacion', l10n.remindersFilterRenewals),
                    ('llamada', l10n.remindersFilterCalls),
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
            const SizedBox(height: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: AmCard(
                  noPad: true,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 0, indent: 18, endIndent: 18, color: AmColors.lineSoftLight),
                    itemBuilder: (_, i) => _ReminderItem(r: filtered[i]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AmPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AmColors.accent : AmColors.cardLight,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: active ? AmColors.accent.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.055),
              blurRadius: active ? 12 : 8,
            ),
          ],
        ),
        child: Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                color: active ? Colors.white : AmColors.inkSoftLight)),
      ),
    );
  }
}

class _ReminderItem extends ConsumerWidget {
  const _ReminderItem({required this.r});
  final MockReminder r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (col, wash, icon) = switch (r.tipo) {
      'pago'       => (AmColors.amberLight, AmColors.amberWashLight, Icons.payments_outlined),
      'renovacion' => (AmColors.accentInk, AmColors.accentWash, Icons.autorenew),
      'llamada'    => (AmColors.greenLight, AmColors.greenWashLight, Icons.phone_outlined),
      _            => (AmColors.mutedLight, AmColors.cardSunkenLight, Icons.notifications_outlined),
    };

    return Opacity(
      opacity: r.hecho ? 0.55 : 1.0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => ref.read(remindersProvider.notifier).toggle(r.id),
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: r.hecho ? AmColors.greenLight : Colors.transparent,
                  border: r.hecho ? null : Border.all(color: AmColors.lineLight, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: r.hecho
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: wash, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 18, color: col),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final c = clientById(r.clienteId);
                  if (c != null) context.push('/clientes/${c.id}');
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.titulo,
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500,
                            color: AmColors.inkLight,
                            decoration: r.hecho ? TextDecoration.lineThrough : null)),
                    Text('${r.sub}${r.hora != '—' ? ' · ${r.hora}' : ''}',
                        style: const TextStyle(fontSize: 12.5, color: AmColors.mutedLight)),
                  ],
                ),
              ),
            ),
            if (r.urgente && !r.hecho)
              Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: AmColors.redLight, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}
