import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/widgets/am_spinner.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/providers/account_provider.dart';
import '../providers/privacy_consent_provider.dart';

/// Pantalla bloqueante: el router manda aquí mientras `privacy.required`.
class PrivacyConsentScreen extends ConsumerWidget {
  const PrivacyConsentScreen({super.key});

  Future<void> _openNotice(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    var ok = false;
    try {
      ok = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(l10n.clientsActionLaunchError)));
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final ok = await ref.read(privacyConsentProvider.notifier).accept();
    if (ok) router.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(privacyConsentProvider);
    final url = ref.watch(agentProfileProvider).asData?.value.privacy.url ?? '';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AmDimens.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(Icons.privacy_tip_outlined, size: 48, color: cs.primary),
                const SizedBox(height: AmDimens.gapM),
                Text(l10n.privacyConsentTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AmDimens.gapS),
                Text(l10n.privacyConsentBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: AmDimens.gapS),
                if (url.isNotEmpty)
                  TextButton(
                    onPressed: () => _openNotice(context, url),
                    child: Text(l10n.privacyConsentReadLink),
                  ),
                CheckboxListTile(
                  value: state.checked,
                  onChanged: state.submitting
                      ? null
                      : (v) => ref.read(privacyConsentProvider.notifier).setChecked(v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.privacyConsentCheckbox),
                ),
                CheckboxListTile(
                  value: state.sensitiveChecked,
                  onChanged: state.submitting
                      ? null
                      : (v) => ref
                          .read(privacyConsentProvider.notifier)
                          .setSensitiveChecked(v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.privacyConsentSensitiveCheckbox),
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AmDimens.gapS),
                    child: Text(context.translateError(state.error),
                        textAlign: TextAlign.center, style: TextStyle(color: cs.error)),
                  ),
                FilledButton(
                  onPressed: state.canAccept ? () => _accept(context, ref) : null,
                  child: state.submitting
                      ? AmSpinner(size: 18, strokeWidth: 2, color: cs.onPrimary)
                      : Text(l10n.privacyConsentAccept),
                ),
                const Spacer(),
                TextButton(
                  onPressed: state.submitting ? null : () => ref.read(authProvider.notifier).signOut(),
                  child: Text(l10n.commonSignOut, style: TextStyle(color: cs.tertiary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
