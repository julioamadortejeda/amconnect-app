import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/forgot_password_provider.dart';
import '../widgets/auth_app_bar.dart';
import '../widgets/forgot_password_email_step.dart';
import '../widgets/forgot_password_reset_step.dart';
import '../widgets/forgot_password_success_view.dart';
import '../../../core/widgets/am_fade_animation.dart';
import '../../../l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_rebuild);
    _codeCtrl.addListener(_rebuild);
    _passCtrl.addListener(_rebuild);
    _confirmCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _emailCtrl.removeListener(_rebuild);
    _codeCtrl.removeListener(_rebuild);
    _passCtrl.removeListener(_rebuild);
    _confirmCtrl.removeListener(_rebuild);
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(forgotPasswordProvider);

    final size = MediaQuery.sizeOf(context);
    final scale = (size.width / 390).clamp(0.80, 1.40);
    final vScale = (size.height / 844).clamp(0.75, 1.40);

    return Scaffold(
      backgroundColor: AmColors.authBg,
      appBar: const AuthAppBar(),
      body: SafeArea(
        top: false,
        bottom: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        28 * scale, 12 * vScale, 28 * scale, 14 * vScale),
                    child: state.done
                        ? ForgotPasswordSuccessView(l10n: l10n, scale: scale, vScale: vScale)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Hero(
                                tag: 'auth_logo',
                                child: ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
                                      Colors.white, BlendMode.srcIn),
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
                                      l10n.forgotPasswordTitle,
                                      style: TextStyle(
                                        fontSize: 34 * scale,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -1.0,
                                        height: 1.05,
                                      ),
                                    ),
                                    SizedBox(height: 8 * vScale),
                                    Text(
                                      state.step == ForgotPasswordStep.email
                                          ? l10n.forgotPasswordSubtitleEmail
                                          : l10n.forgotPasswordCodeSentTo(
                                              state.email),
                                      style: TextStyle(
                                        fontSize: 15 * scale,
                                        height: 1.55,
                                        color: AmColors.authSubtitle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              AmFadeAnimation(
                                delayMs: 250,
                                child: state.step == ForgotPasswordStep.email
                                    ? ForgotPasswordEmailStep(
                                        l10n: l10n,
                                        state: state,
                                        emailCtrl: _emailCtrl,
                                        scale: scale,
                                        vScale: vScale,
                                        onSubmit: () => ref
                                            .read(
                                                forgotPasswordProvider.notifier)
                                            .requestCode(_emailCtrl.text),
                                      )
                                    : ForgotPasswordResetStep(
                                        l10n: l10n,
                                        state: state,
                                        codeCtrl: _codeCtrl,
                                        passCtrl: _passCtrl,
                                        confirmCtrl: _confirmCtrl,
                                        obscurePass: _obscurePass,
                                        obscureConfirm: _obscureConfirm,
                                        onTogglePass: () => setState(
                                            () => _obscurePass = !_obscurePass),
                                        onToggleConfirm: () => setState(() =>
                                            _obscureConfirm = !_obscureConfirm),
                                        scale: scale,
                                        vScale: vScale,
                                        onSubmit: () => ref
                                            .read(
                                                forgotPasswordProvider.notifier)
                                            .confirmReset(
                                              code: _codeCtrl.text,
                                              password: _passCtrl.text,
                                              confirm: _confirmCtrl.text,
                                            ),
                                        onBackToEmail: () => ref
                                            .read(
                                                forgotPasswordProvider.notifier)
                                            .backToEmail(),
                                      ),
                              ),
                              SizedBox(height: 8 * vScale),
                            ],
                          ),
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
