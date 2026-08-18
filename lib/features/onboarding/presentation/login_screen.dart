import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../providers/login_provider.dart';
import '../widgets/login_social_btn.dart';
import '../widgets/login_email_btn.dart';
import '../../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final scale = (size.width / AmDimens.authBaseWidth).clamp(0.80, 1.40);
    final state = ref.watch(loginProvider);
    final notifier = ref.read(loginProvider.notifier);

    ref.listen(loginProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        final msg = switch (next.error!) {
          LoginError.google => l10n.loginErrGoogle,
          LoginError.apple => l10n.loginErrApple,
          LoginError.email => l10n.errWrongCredentials,
        };
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AmColors.redLight,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    });

    return Scaffold(
      backgroundColor: AmColors.authBg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AmDimens.authPadH * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Hero(
                tag: 'auth_logo',
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  child: Image.asset('assets/logo/logo_t.png',
                      width: 150, height: 150),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.loginWelcomeTitle,
                style: TextStyle(
                  fontSize: 38 * scale,
                  fontWeight: FontWeight.w800,
                  color: AmColors.white,
                  letterSpacing: -0.5,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.loginWelcomeSubtitle,
                style: TextStyle(
                    fontSize: 15 * scale, height: 1.55, color: AmColors.authSubtitle),
              ),
              const Spacer(),
              if (Platform.isIOS) ...[
                LoginSocialBtn(
                  onTap: state.isLoading ? null : notifier.signInWithApple,
                  icon: const Icon(Icons.apple,
                      size: 22, color: AmColors.inkLight),
                  label: l10n.loginContinueApple,
                ),
                const SizedBox(height: 10),
              ],
              LoginSocialBtn(
                onTap: state.isLoading ? null : notifier.signInWithGoogle,
                icon: Image.asset('assets/google_logo.png',
                    width: 20, height: 20),
                label: l10n.loginContinueGoogle,
              ),
              const SizedBox(height: 10),
              LoginEmailBtn(
                onTap:
                    state.isLoading ? null : () => context.push('/email-login'),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.center,
                child: Text(
                  l10n.commonTerms,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12 * scale,
                      color: AmColors.authSubtitle,
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
