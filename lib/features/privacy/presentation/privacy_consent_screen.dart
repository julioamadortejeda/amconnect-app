import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/widgets/am_check_row.dart';
import '../../../core/widgets/am_fade_animation.dart';
import '../../../core/widgets/am_group_card.dart';
import '../../../core/widgets/am_press.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/providers/account_provider.dart';
import '../../onboarding/widgets/auth_error_msg.dart';
import '../../onboarding/widgets/auth_submit_btn.dart';
import '../providers/privacy_consent_provider.dart';

/// Pantalla bloqueante: el router manda aquí mientras `privacy.required`.
/// Mismo lenguaje visual que las pantallas de auth (fondo azul, logo blanco).
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
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(privacyConsentProvider);
    final notifier = ref.read(privacyConsentProvider.notifier);
    final url = ref.watch(agentProfileProvider).asData?.value.privacy.url ?? '';
    final size = MediaQuery.sizeOf(context);
    final scale = (size.width / AmDimens.authBaseWidth).clamp(0.80, 1.40);
    final vScale = (size.height / AmDimens.authBaseHeight).clamp(0.75, 1.40);
    final linkStyle = TextStyle(
      fontSize: 14 * scale,
      color: AmColors.white,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: AmColors.white,
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AmColors.authBg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        AmDimens.authPadH * scale,
                        AmDimens.authPadTop * vScale,
                        AmDimens.authPadH * scale,
                        AmDimens.authPadBottom * vScale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'auth_logo',
                          child: ColorFiltered(
                            colorFilter:
                                const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            child: Image.asset('assets/logo/logo_t.png',
                                width: 72 * scale, height: 72 * scale),
                          ),
                        ),
                        SizedBox(height: 24 * vScale),
                        AmFadeAnimation(
                          delayMs: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.privacyConsentTitle,
                                style: TextStyle(
                                  fontSize: 38 * scale,
                                  fontWeight: FontWeight.w800,
                                  color: AmColors.white,
                                  letterSpacing: -1.0,
                                  height: 1.05,
                                ),
                              ),
                              SizedBox(height: 8 * vScale),
                              Text(
                                l10n.privacyConsentBody,
                                style: TextStyle(
                                  fontSize: 15 * scale,
                                  height: 1.55,
                                  color: AmColors.authSubtitle,
                                ),
                              ),
                              if (url.isNotEmpty) ...[
                                SizedBox(height: 12 * vScale),
                                AmPress(
                                  onTap: () => _openNotice(context, url),
                                  child: Text(l10n.privacyConsentReadLink, style: linkStyle),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(height: 20 * vScale),
                        AmFadeAnimation(
                          delayMs: 250,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AmGroupCard(children: [
                                AmCheckRow(
                                  label: l10n.privacyConsentCheckbox,
                                  value: state.checked,
                                  onChanged: state.submitting ? null : notifier.setChecked,
                                ),
                                Divider(
                                    height: 1,
                                    indent: AmDimens.cardPad,
                                    endIndent: AmDimens.cardPad,
                                    color: Theme.of(context).colorScheme.outlineVariant),
                                AmCheckRow(
                                  label: l10n.privacyConsentSensitiveCheckbox,
                                  value: state.sensitiveChecked,
                                  onChanged:
                                      state.submitting ? null : notifier.setSensitiveChecked,
                                ),
                              ]),
                              if (state.error != null) ...[
                                SizedBox(height: 12 * vScale),
                                AuthErrorMsg(
                                  message: context.translateError(state.error),
                                  scale: scale,
                                ),
                              ],
                              SizedBox(height: 20 * vScale),
                              AuthSubmitBtn(
                                label: l10n.privacyConsentAccept,
                                enabled: state.canAccept || state.submitting,
                                isLoading: state.submitting,
                                onTap: () => _accept(context, ref),
                              ),
                              SizedBox(height: 16 * vScale),
                              Center(
                                child: AmPress(
                                  onTap: state.submitting
                                      ? null
                                      : () => ref.read(authProvider.notifier).signOut(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Text(
                                      l10n.commonSignOut,
                                      style: TextStyle(
                                        fontSize: 14 * scale,
                                        color: AmColors.authSubtitle,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AmColors.authSubtitle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
