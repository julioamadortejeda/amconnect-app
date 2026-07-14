import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/am_theme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/am_press.dart';
import '../../../../core/widgets/am_badge.dart';
import '../../../../core/widgets/am_section_label.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/providers/home_provider.dart';

// ─── Factory ─────────────────────────────────────────────────────────────────

/// Returns a premium card widget if the [metadata] contains a known type,
/// otherwise returns null so the caller can fall back to a text bubble.
Widget? buildChatCard(Map<String, dynamic> metadata, BuildContext context) {
  final type = metadata['type'] as String?;
  switch (type) {
    case 'policy_confirmed':
      return _PolicyConfirmedCard(data: metadata);
    case 'policy_updated':
      return _PolicyConfirmedCard(data: metadata, isUpdate: true);
    case 'contact_created':
      return _ContactCreatedCard(data: metadata);
    case 'reminder_created':
      return _ReminderCreatedCard(data: metadata);
    case 'contact_info':
      return _ContactInfoCard(data: metadata);
    case 'contact_list':
      return _ContactListCarousel(data: metadata);
    case 'reminder_list':
      return _ReminderListCard(data: metadata);
    case 'policy_info':
      return _PolicyInfoCard(data: metadata);
    default:
      return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  POLICY CONFIRMED CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _PolicyConfirmedCard extends StatelessWidget {
  const _PolicyConfirmedCard({required this.data, this.isUpdate = false});
  final Map<String, dynamic> data;
  final bool isUpdate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final carrier = data['carrierName'] as String? ?? '';
    final branch = data['branchName'] as String? ?? '';
    final holder = data['holderName'] as String? ?? '';
    final policyNumber = data['policyNumber'] as String? ?? '';
    final policyId = data['policyId'] as String? ?? '';
    final remindersMap = data['reminders'] as Map<String, dynamic>? ?? {};
    final reminders = [
      ...(remindersMap['created'] as List? ?? []),
      ...(remindersMap['existing'] as List? ?? []),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AmShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: am.greenWash,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.check_circle_rounded, color: am.green, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUpdate ? 'Póliza actualizada' : 'Póliza creada',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      if (policyNumber.isNotEmpty)
                        Text(
                          '#$policyNumber',
                          style: TextStyle(fontSize: 12, color: cs.tertiary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),

          // ── Body fields ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (carrier.isNotEmpty)
                  _DetailRow(icon: Icons.business_rounded, label: 'Aseguradora', value: carrier),
                if (branch.isNotEmpty)
                  _DetailRow(icon: Icons.category_rounded, label: 'Ramo', value: branch),
                if (holder.isNotEmpty)
                  _DetailRow(icon: Icons.person_rounded, label: 'Contratante', value: holder),
              ],
            ),
          ),

          // ── Auto-generated reminders ────────────────────────────
          if (reminders.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
              child: AmSectionLabel(
                label: 'Recordatorios',
                trailing: AmBadge(label: '${reminders.length}', tone: AmBadgeTone.accent),
              ),
            ),
            ...reminders.take(3).map((r) {
              final title = (r is Map ? r['title'] : null) as String? ?? 'Recordatorio';
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, size: 13, color: am.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(title,
                          style: TextStyle(fontSize: 12, color: cs.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
          ],

          // ── Action button ──────────────────────────────────────
          if (policyId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: _CardActionButton(
                label: 'Ver Póliza',
                icon: Icons.arrow_forward_rounded,
                color: cs.primary,
                onTap: () => context.push('/policy/$policyId'),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CONTACT CREATED CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ContactCreatedCard extends StatelessWidget {
  const _ContactCreatedCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final fullName = data['fullName'] as String? ?? 'Contacto';
    final email = data['email'] as String?;
    final phone = data['phone'] as String?;
    final isProspect = data['isProspect'] as bool? ?? false;
    final contactId = data['contactId'] as String? ?? '';

    // Initials
    final initials = getInitials(fullName);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: am.green.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: am.green.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                // Avatar with gradient initials
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isProspect
                          ? [am.amber, const Color(0xFFFF8F00)]
                          : [am.green, const Color(0xFF00C853)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (isProspect ? am.amber : am.green).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isProspect ? am.amberWash : am.greenWash,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isProspect ? 'Prospecto' : 'Cliente',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isProspect ? am.amber : am.green,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle_rounded, color: am.green, size: 22),
              ],
            ),
          ),

          // ── Contact details ─────────────────────────────────────
          if (phone != null || email != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Column(
                children: [
                  if (phone != null)
                    _DetailRow(icon: Icons.phone_rounded, label: 'Teléfono', value: phone),
                  if (email != null)
                    _DetailRow(icon: Icons.email_rounded, label: 'Correo', value: email),
                ],
              ),
            ),

          // ── Action ──────────────────────────────────────────────
          if (contactId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _CardActionButton(
                label: 'Ver Perfil',
                icon: Icons.arrow_forward_rounded,
                color: am.green,
                onTap: () => context.push('/clients/$contactId?fromChat=true'),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  REMINDER CREATED CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ReminderCreatedCard extends StatelessWidget {
  const _ReminderCreatedCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final title = data['title'] as String? ?? 'Recordatorio';
    final description = data['description'] as String?;
    final dueDate = data['dueDate'] as String?;
    final clientName = data['clientName'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: am.amber.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: am.amber.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [am.amber, const Color(0xFFFF8F00)],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: am.amber.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.alarm_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (clientName != null)
                        Text(
                          clientName,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle_rounded, color: am.amber, size: 22),
              ],
            ),
          ),

          // ── Details ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dueDate != null)
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Fecha',
                    value: fmtSmartDateTime(DateTime.tryParse(dueDate), l10n,
                        showYear: true),
                  ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description,
                      style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // ── Action ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: _CardActionButton(
              label: 'Ir a Agenda',
              icon: Icons.arrow_forward_rounded,
              color: am.amber,
              onTap: () => context.go('/reminders'),
            ),
          ),
        ],
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════════════════════════
//  CONTACT INFO CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final fullName = data['fullName'] as String? ?? 'Contacto';
    final email = data['email'] as String?;
    final phone = data['phone'] as String?;
    final isProspect = data['isProspect'] as bool? ?? false;
    final contactId = data['contactId'] as String? ?? '';
    final initials = getInitials(fullName);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AmDimens.cardPad),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isProspect
                          ? [am.amber, const Color(0xFFFF8F00)]
                          : [am.green, const Color(0xFF00C853)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isProspect ? am.amberWash : am.greenWash,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isProspect ? l10n.clientsStatusProspect : l10n.clientsNewClient,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isProspect ? am.amber : am.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (phone != null || email != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AmDimens.cardPad),
              child: Divider(height: 1, color: cs.outline.withValues(alpha: 0.08)),
            ),
            Padding(
              padding: const EdgeInsets.all(AmDimens.cardPad),
              child: Column(
                children: [
                  if (phone != null && phone.isNotEmpty)
                    _DetailRow(icon: Icons.phone_rounded, label: l10n.clientsContactSection, value: phone),
                  if (email != null && email.isNotEmpty)
                    _DetailRow(icon: Icons.email_rounded, label: 'Email', value: email),
                ],
              ),
            ),
          ],
          if (contactId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AmDimens.cardPad, 0, AmDimens.cardPad, AmDimens.cardPad),
              child: _CardActionButton(
                label: l10n.chatCardViewProfile,
                icon: Icons.arrow_forward_rounded,
                color: isProspect ? am.amber : am.green,
                onTap: () => context.push('/clients/$contactId?fromChat=true'),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CONTACT LIST CAROUSEL
// ═══════════════════════════════════════════════════════════════════════════════

class _ContactListCarousel extends StatelessWidget {
  const _ContactListCarousel({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final list = data['contacts'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(AmDimens.cardPad),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_outlined, color: cs.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.chatCardContactListTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AmDimens.gapS),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length > 5 ? 5 : list.length,
            itemBuilder: (context, index) {
              final map = list[index] as Map<String, dynamic>? ?? {};
              final id = map['id'] as String? ?? '';
              final fullName = map['fullName'] as String? ?? '';
              final phone = map['phone'] as String?;
              final initials = getInitials(fullName);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AmPress(
                  onTap: () => context.push('/clients/$id?fromChat=true'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: cs.secondaryContainer,
                          child: Text(
                            initials,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSecondaryContainer),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (phone != null && phone.isNotEmpty)
                                Text(
                                  phone,
                                  style: TextStyle(fontSize: 11, color: cs.tertiary),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 18, color: cs.tertiary),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  REMINDER LIST CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ReminderListCard extends ConsumerStatefulWidget {
  const _ReminderListCard({required this.data});
  final Map<String, dynamic> data;

  @override
  ConsumerState<_ReminderListCard> createState() => _ReminderListCardState();
}

class _ReminderListCardState extends ConsumerState<_ReminderListCard> {
  final Set<String> _completedIds = {};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final list = widget.data['reminders'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(AmDimens.cardPad),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        border: Border.all(color: am.amber.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, color: am.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.chatCardReminderListTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: am.amber,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AmDimens.gapS),
          ...list.map((item) {
            final map = item as Map<String, dynamic>? ?? {};
            final id = map['id'] as String? ?? '';
            final title = map['title'] as String? ?? 'Recordatorio';
            final dueDate = map['dueDate'] as String?;
            final clientName = map['clientName'] as String?;
            final isDone = _completedIds.contains(id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  AmPress(
                    onTap: () {
                      if (id.isNotEmpty && !isDone) {
                        setState(() {
                          _completedIds.add(id);
                        });
                        ref.read(remindersProvider.notifier).toggle(id);
                      }
                    },
                    child: Icon(
                      isDone ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                      color: isDone ? am.green : cs.tertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDone ? cs.tertiary : cs.onSurface,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (clientName != null || dueDate != null)
                          Text(
                            [
                              if (clientName != null) clientName,
                              if (dueDate != null)
                                fmtSmartDateTime(
                                    DateTime.tryParse(dueDate), l10n),
                            ].join(' · '),
                            style: TextStyle(fontSize: 11, color: cs.tertiary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          _CardActionButton(
            label: l10n.chatCardGoToAgenda,
            icon: Icons.arrow_forward_rounded,
            color: am.amber,
            onTap: () => context.push('/reminders'),
          ),
        ],
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════════════════════════
//  POLICY INFO CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _PolicyInfoCard extends StatelessWidget {
  const _PolicyInfoCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final carrier = data['carrierName'] as String? ?? '';
    final branch = data['branchName'] as String? ?? '';
    final holder = data['holderName'] as String? ?? '';
    final productName = data['productName'] as String? ?? '';
    final policyNumber = data['policyNumber'] as String? ?? '';
    final contactId = data['contactId'] as String? ?? '';
    final premium = data['premium'];
    final sumInsured = data['sumInsured'];
    final endDate = data['endDate'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        border: Border.all(color: AmColors.accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AmColors.accent.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AmColors.accent, Color(0xFF2AB5FF)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AmDimens.cardRadius - 1),
                topRight: Radius.circular(AmDimens.cardRadius - 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.chatCardPolicyInfoTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (policyNumber.isNotEmpty)
                        Text(
                          '#$policyNumber',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AmDimens.cardPad),
            child: Column(
              children: [
                if (carrier.isNotEmpty)
                  _DetailRow(icon: Icons.business_rounded, label: 'Aseguradora', value: carrier),
                if (branch.isNotEmpty)
                  _DetailRow(icon: Icons.category_rounded, label: 'Ramo', value: branch),
                if (productName.isNotEmpty)
                  _DetailRow(icon: Icons.inventory_2_rounded, label: 'Producto', value: productName),
                if (holder.isNotEmpty)
                  _DetailRow(icon: Icons.person_rounded, label: 'Asegurado', value: holder),
                if (premium != null)
                  _DetailRow(
                    icon: Icons.monetization_on_rounded,
                    label: l10n.clientsPolicyPremium,
                    value: fmtCurrency((premium as num?)?.toDouble()),
                  ),
                if (sumInsured != null)
                  _DetailRow(
                    icon: Icons.payments_rounded,
                    label: l10n.clientsPolicySumInsured,
                    value: fmtCurrency((sumInsured as num?)?.toDouble()),
                  ),
                if (endDate != null)
                  _DetailRow(icon: Icons.calendar_today_rounded, label: l10n.clientsPolicyEndDate, value: fmtDateFromIso(endDate)),
              ],
            ),
          ),
          if (contactId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AmDimens.cardPad, 0, AmDimens.cardPad, AmDimens.cardPad),
              child: _CardActionButton(
                label: l10n.chatCardViewProfile,
                icon: Icons.person_rounded,
                color: AmColors.accent,
                onTap: () => context.push('/clients/$contactId?fromChat=true'),
              ),
            ),
        ],
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════════════════════════
//  SHARED INTERNAL WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.tertiary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: cs.tertiary, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.5, color: cs.onSurface, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AmPress(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
