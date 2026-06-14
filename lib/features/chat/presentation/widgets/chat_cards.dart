import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/am_theme.dart';
import '../../../../core/widgets/am_press.dart';

// ─── Factory ─────────────────────────────────────────────────────────────────

/// Returns a premium card widget if the [metadata] contains a known type,
/// otherwise returns null so the caller can fall back to a text bubble.
Widget? buildChatCard(Map<String, dynamic> metadata, BuildContext context) {
  final type = metadata['type'] as String?;
  switch (type) {
    case 'policy_confirmed':
      return _PolicyConfirmedCard(data: metadata);
    case 'contact_created':
      return _ContactCreatedCard(data: metadata);
    case 'reminder_created':
      return _ReminderCreatedCard(data: metadata);
    default:
      return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  POLICY CONFIRMED CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _PolicyConfirmedCard extends StatelessWidget {
  const _PolicyConfirmedCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final carrier = data['carrierName'] as String? ?? '';
    final branch = data['branchName'] as String? ?? '';
    final holder = data['holderName'] as String? ?? '';
    final policyNumber = data['policyNumber'] as String? ?? '';
    final policyId = data['policyId'] as String? ?? '';
    final reminders = data['reminders'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AmColors.accent.withValues(alpha: 0.08),
            AmColors.accent.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AmColors.accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AmColors.accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007AC0), Color(0xFF2AB5FF)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
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
                        'Póliza Creada',
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
                Icon(Icons.check_circle_rounded, color: Colors.white.withValues(alpha: 0.85), size: 22),
              ],
            ),
          ),

          // ── Body fields ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
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
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Divider(height: 1, color: cs.outline.withValues(alpha: 0.15)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Text(
                'Recordatorios automáticos',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.tertiary,
                  letterSpacing: 0.2,
                ),
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
          ],

          // ── Action button ──────────────────────────────────────
          if (policyId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: _CardActionButton(
                label: 'Ver Póliza',
                icon: Icons.arrow_forward_rounded,
                color: AmColors.accent,
                onTap: () {
                  // Future: navigate to policy detail when route exists
                },
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
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : fullName.substring(0, fullName.length.clamp(0, 2)).toUpperCase();

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
                onTap: () => context.push('/clients/$contactId'),
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
                    value: _formatDate(dueDate),
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

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = dt.difference(now);

      String dayPart;
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        dayPart = 'Hoy';
      } else if (diff.inDays == 1 ||
          (dt.day == now.day + 1 && dt.month == now.month && dt.year == now.year)) {
        dayPart = 'Mañana';
      } else {
        dayPart = '${dt.day}/${dt.month}/${dt.year}';
      }

      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$dayPart, $hour:$minute';
    } catch (_) {
      return iso;
    }
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
