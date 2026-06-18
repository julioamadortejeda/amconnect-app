import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
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
        const SizedBox(width: 9),
        _Action(
          customIcon: Image.asset(
            'assets/logo/logo_t.png',
            color: Colors.white,
            width: 20,
            height: 20,
          ),
          label: l10n.clientsActionAsk,
          onTap: () => context.push('/chat'),
          accent: true,
        ),
      ],
    );
  }
}

class _Action extends StatefulWidget {
  const _Action({
    this.icon,
    this.customIcon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final IconData? icon;
  final Widget? customIcon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

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
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: widget.accent
                    ? AmColors.accent.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.055),
                blurRadius: widget.accent ? 12 : 16,
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.accent ? AmColors.accent : cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: widget.customIcon ??
                        Icon(
                          widget.icon,
                          size: 19,
                          color: widget.accent
                              ? Colors.white
                              : cs.onPrimaryContainer,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5,
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
