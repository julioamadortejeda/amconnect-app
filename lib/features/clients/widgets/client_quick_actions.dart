import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/features.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../feed/widgets/ingest_type_picker.dart';

class ClientQuickActions extends StatelessWidget {
  const ClientQuickActions({super.key, required this.clientId, this.phone});

  final String clientId;
  final String? phone;

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _call(BuildContext context, AppLocalizations l10n) async {
    if (phone == null || phone!.trim().isEmpty) {
      _showSnack(context, l10n.clientsActionNoPhone);
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone!.trim());
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (context.mounted) {
        _showSnack(context, l10n.clientsActionLaunchError);
      }
    } catch (_) {
      if (context.mounted) _showSnack(context, l10n.clientsActionLaunchError);
    }
  }

  Future<void> _message(BuildContext context, AppLocalizations l10n) async {
    if (phone == null || phone!.trim().isEmpty) {
      _showSnack(context, l10n.clientsActionNoPhone);
      return;
    }
    final digits = whatsAppDigits(phone!);
    if (digits == null) {
      _showSnack(context, l10n.clientsActionInvalidPhone);
      return;
    }
    final uri = Uri.parse('https://wa.me/$digits');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        _showSnack(context, l10n.clientsActionLaunchError);
      }
    } catch (_) {
      if (context.mounted) _showSnack(context, l10n.clientsActionLaunchError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _Action(
          icon: const Icon(Icons.phone_outlined),
          label: l10n.clientsActionCall,
          onTap: () => _call(context, l10n),
        ),
        const SizedBox(width: 9),
        _Action(
          icon: const FaIcon(FontAwesomeIcons.whatsapp),
          label: l10n.clientsActionMessage,
          onTap: () => _message(context, l10n),
        ),
        if (kManualReminderCreationEnabled) ...[
          const SizedBox(width: 9),
          _Action(
            icon: const Icon(Icons.notifications_none_outlined),
            label: l10n.clientsActionRemind,
            onTap: () => context.push('/create-reminder?cliente=$clientId'),
          ),
        ],
        const SizedBox(width: 9),
        _Action(
          icon: const Icon(Icons.upload_file_outlined),
          label: l10n.clientsActionUpload,
          onTap: () => IngestTypePicker.show(context, contactId: clientId),
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

  final Widget icon;
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
                    child: IconTheme(
                      data: IconThemeData(size: 16, color: cs.onPrimaryContainer),
                      child: widget.icon,
                    ),
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
