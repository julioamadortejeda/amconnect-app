import 'package:flutter/material.dart';
import '../../../core/widgets/am_spinner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/permission_provider.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_confirm_dialog.dart';
import '../../../core/widgets/am_group_card.dart';
import '../../../core/widgets/am_info_row.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../providers/account_provider.dart';
import '../widgets/account_plan_card.dart';
import '../widgets/account_profile_hero.dart';
import '../widgets/account_theme_selector.dart';
import '../../../l10n/app_localizations.dart';

const _kSupportEmail = 'jacatsoft@gmail.com';

// El equipo de soporte lee en español siempre, sin importar el idioma del
// dispositivo del asesor — a diferencia del resto de la UI, este texto no
// pasa por AppLocalizations porque su destinatario no es el usuario de la app.
const _kSupportEmailSubject = 'AmConnect – Reporte';
String _supportEmailBody(String agentEmail) =>
    'Cuéntanos qué pasó:\n\n\n—\nAsesor: $agentEmail';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _editing = false;
  bool _saving = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _enterEdit(String fullName, String? phone) {
    _nameCtrl.text = fullName;
    _phoneCtrl.text = phone ?? '';
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(agentProfileProvider.notifier).updateProfile(
            fullName: name,
            phone: _phoneCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
      });
      _showSnack(l10n.accountSaved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack(l10n.accountErrSave);
    }
  }

  Future<void> _openSupportEmail(AppLocalizations l10n, String agentEmail) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _kSupportEmail,
      queryParameters: {
        'subject': _kSupportEmailSubject,
        'body': _supportEmailBody(agentEmail),
      },
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        _showSnack(l10n.clientsActionLaunchError);
      }
    } catch (_) {
      if (mounted) _showSnack(l10n.clientsActionLaunchError);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  void _confirmSignOut(AppLocalizations l10n, ColorScheme cs) {
    final notifier = ref.read(authProvider.notifier);
    showDialog(
      context: context,
      builder: (_) => AmConfirmDialog(
        title: l10n.accountSignOutTitle,
        message: l10n.accountSignOutMessage,
        confirmLabel: l10n.commonSignOut,
        cancelLabel: l10n.commonCancel,
        icon: Icons.logout,
        iconBgColor: cs.errorContainer,
        iconFgColor: cs.error,
        onConfirm: () => notifier.signOut(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (!ref.watch(accountReadyProvider).hasValue) {
      return Scaffold(
        appBar: AmTopBar(title: l10n.commonAccount, showBack: true),
        body: const AmLoader(),
      );
    }

    final profile = ref.watch(agentProfileProvider).asData?.value;
    final subscription = ref.watch(subscriptionInfoProvider).asData?.value;
    final notifPermission = ref.watch(notificationPermissionStatusProvider).asData?.value;
    final showNotifRow = notifPermission != null &&
        (notifPermission.isDenied || notifPermission.isPermanentlyDenied);
    if (profile == null || subscription == null) {
      return Scaffold(
        appBar: AmTopBar(title: l10n.commonAccount, showBack: true),
        body: const AmLoader(),
      );
    }

    final trailingBar = _editing
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => setState(() => _editing = false),
                child: Text(l10n.commonCancel, style: TextStyle(color: cs.tertiary)),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? AmSpinner(size: 16, strokeWidth: 2, color: cs.onPrimary)
                    : Text(
                        l10n.accountSave,
                        style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(width: 4),
            ],
          )
        : const SizedBox.shrink();

    return Scaffold(
      appBar: AmTopBar(
        title: l10n.commonAccount,
        showBack: true,
        actions: [
          Padding(padding: const EdgeInsets.only(right: 8.0), child: trailingBar),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AmDimens.screenH, AmDimens.gapM, AmDimens.screenH, AmDimens.gapM),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AmDimens.gapM * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AmSectionLabel(label: l10n.accountProfileTitle),
                      const SizedBox(height: AmDimens.gapXS),
                      AccountProfileHero(
                        profile: profile,
                        editing: _editing,
                        nameCtrl: _nameCtrl,
                        phoneCtrl: _phoneCtrl,
                        onEdit: () => _enterEdit(profile.fullName, profile.phone),
                      ),
                      const SizedBox(height: AmDimens.gapL),
                      AmSectionLabel(label: l10n.accountPlanTitle),
                      const SizedBox(height: AmDimens.gapXS),
                      AccountPlanCard(info: subscription),
                      const SizedBox(height: AmDimens.gapL),
                      AmSectionLabel(label: l10n.accountAppearanceTitle),
                      const SizedBox(height: AmDimens.gapXS),
                      const AccountThemeSelector(),
                      const SizedBox(height: AmDimens.gapL),
                      AmSectionLabel(label: l10n.accountHelpTitle),
                      const SizedBox(height: AmDimens.gapXS),
                      AmGroupCard(children: [
                        AmInfoRow(
                          icon: Icons.help_outline,
                          label: l10n.accountHelp,
                          trailing: const SizedBox.shrink(),
                          chevron: true,
                          onTap: () => _openSupportEmail(l10n, profile.email),
                        ),
                        if (showNotifRow)
                          AmInfoRow(
                            icon: Icons.notifications_off_outlined,
                            label: l10n.accountNotificationsDisabled,
                            trailing: Text(l10n.commonOpenSettings,
                                style: TextStyle(fontSize: 13, color: cs.primary)),
                            chevron: true,
                            onTap: () => openAppSettings(),
                          ),
                      ]),
                      const Spacer(),
                      const SizedBox(height: AmDimens.gapL),
                      AmPress(
                        onTap: () => _confirmSignOut(l10n, cs),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AmDimens.gapS),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius: BorderRadius.circular(AmDimens.cardRadius),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, size: 18, color: cs.error),
                              const SizedBox(width: 8),
                              Text(
                                l10n.commonSignOut,
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: cs.error),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
