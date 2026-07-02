import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_confirm_dialog.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../providers/account_provider.dart';
import '../widgets/account_plan_card.dart';
import '../widgets/account_profile_hero.dart';
import '../../../l10n/app_localizations.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.accountSaved),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.accountErrSave),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
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
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                      )
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AmDimens.screenH, AmDimens.gapM, AmDimens.screenH, 40),
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
    );
  }
}
