import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../l10n/app_localizations.dart';

class ClientQuickActions extends StatelessWidget {
  const ClientQuickActions({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _Action(
          icon: Icons.phone_outlined,
          label: l10n.clientsActionCall,
          onTap: () {},
        ),
        const SizedBox(width: 9),
        _Action(
          icon: Icons.chat_bubble_outline,
          label: l10n.clientsActionMessage,
          onTap: () {},
        ),
        const SizedBox(width: 9),
        _Action(
          icon: Icons.notifications_none_outlined,
          label: l10n.clientsActionRemind,
          onTap: () => context.push('/create-reminder?cliente=$clientId'),
        ),
      ],
    );
  }
}

class _Action extends StatefulWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_Action> createState() => _ActionState();
}

class _ActionState extends State<_Action> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _pressed = true);
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AmDimens.cardRadius - 3),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.055),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            children: [
              AnimatedScale(
                scale: _pressed ? 0.88 : 1.0,
                duration: const Duration(milliseconds: 110),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(widget.icon, size: 16, color: cs.onPrimaryContainer),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
