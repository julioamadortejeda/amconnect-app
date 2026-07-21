import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/forgot_password_provider.dart';
import '../widgets/auth_app_bar.dart';
import '../widgets/auth_error_msg.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_submit_btn.dart';
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
                        ? _SuccessView(l10n: l10n, scale: scale, vScale: vScale)
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
                                    ? _EmailStep(
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
                                    : _ResetStep(
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

class _EmailStep extends ConsumerWidget {
  const _EmailStep({
    required this.l10n,
    required this.state,
    required this.emailCtrl,
    required this.scale,
    required this.vScale,
    required this.onSubmit,
  });

  final AppLocalizations l10n;
  final ForgotPasswordState state;
  final TextEditingController emailCtrl;
  final double scale;
  final double vScale;
  final VoidCallback onSubmit;

  String? _errorMsg() => switch (state.error) {
        ForgotPasswordError.emptyEmail => l10n.errEmptyCredentials,
        ForgotPasswordError.invalidEmail => l10n.errInvalidEmail,
        ForgotPasswordError.requestFailed => l10n.errRequestCodeFailed,
        _ => null,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMsg = _errorMsg();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AuthField(
          controller: emailCtrl,
          hint: l10n.fieldEmail,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        if (errorMsg != null) ...[
          SizedBox(height: 10 * vScale),
          AuthErrorMsg(
            message: errorMsg,
            scale: scale,
            onDismiss: () =>
                ref.read(forgotPasswordProvider.notifier).clearError(),
          ),
        ],
        SizedBox(height: 20 * vScale),
        AuthSubmitBtn(
          label: l10n.forgotPasswordSendCodeBtn,
          enabled: emailCtrl.text.trim().isNotEmpty,
          isLoading: state.isLoading,
          onTap: onSubmit,
        ),
      ],
    );
  }
}

class _ResetStep extends ConsumerWidget {
  const _ResetStep({
    required this.l10n,
    required this.state,
    required this.codeCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.scale,
    required this.vScale,
    required this.onSubmit,
    required this.onBackToEmail,
  });

  final AppLocalizations l10n;
  final ForgotPasswordState state;
  final TextEditingController codeCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePass;
  final bool obscureConfirm;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;
  final double scale;
  final double vScale;
  final VoidCallback onSubmit;
  final VoidCallback onBackToEmail;

  String? _errorMsg() => switch (state.error) {
        ForgotPasswordError.emptyFields => l10n.errFillAll,
        ForgotPasswordError.passwordMismatch => l10n.errPasswordMismatch,
        ForgotPasswordError.invalidCode => l10n.errInvalidCode,
        _ => null,
      };

  bool get _canSubmit =>
      codeCtrl.text.trim().isNotEmpty &&
      passCtrl.text.isNotEmpty &&
      confirmCtrl.text.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMsg = _errorMsg();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AuthField(
          controller: codeCtrl,
          hint: l10n.fieldCode,
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: 12 * vScale),
        AuthField(
          controller: passCtrl,
          hint: l10n.fieldPassword,
          icon: Icons.lock_outline,
          obscure: obscurePass,
          textInputAction: TextInputAction.next,
          suffixIcon: GestureDetector(
            onTap: onTogglePass,
            child: Icon(
              obscurePass
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AmColors.white,
              size: 20,
            ),
          ),
        ),
        SizedBox(height: 12 * vScale),
        AuthField(
          controller: confirmCtrl,
          hint: l10n.fieldConfirm,
          icon: Icons.lock_outline,
          obscure: obscureConfirm,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          suffixIcon: GestureDetector(
            onTap: onToggleConfirm,
            child: Icon(
              obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AmColors.white,
              size: 20,
            ),
          ),
        ),
        if (errorMsg != null) ...[
          SizedBox(height: 10 * vScale),
          AuthErrorMsg(
            message: errorMsg,
            scale: scale,
            onDismiss: () =>
                ref.read(forgotPasswordProvider.notifier).clearError(),
          ),
        ],
        SizedBox(height: 20 * vScale),
        AuthSubmitBtn(
          label: l10n.forgotPasswordResetBtn,
          enabled: _canSubmit,
          isLoading: state.isLoading,
          onTap: onSubmit,
        ),
        SizedBox(height: 14 * vScale),
        GestureDetector(
          onTap: onBackToEmail,
          child: Text(
            l10n.forgotPasswordBackToEmail,
            style: TextStyle(
              fontSize: 13 * scale,
              color: AmColors.authSubtitle,
              decoration: TextDecoration.underline,
              decorationColor: AmColors.authSubtitle,
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.l10n,
    required this.scale,
    required this.vScale,
  });

  final AppLocalizations l10n;
  final double scale;
  final double vScale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72 * scale,
            height: 72 * scale,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                size: 38 * scale, color: Colors.white),
          ),
          SizedBox(height: 20 * vScale),
          Text(
            l10n.forgotPasswordSuccessTitle,
            style: TextStyle(
              fontSize: 22 * scale,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8 * vScale),
          Text(
            l10n.forgotPasswordSuccessMsg,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14 * scale,
              color: AmColors.authSubtitle,
              height: 1.5,
            ),
          ),
          SizedBox(height: 28 * vScale),
          AuthSubmitBtn(
            label: l10n.forgotPasswordSuccessBtn,
            enabled: true,
            isLoading: false,
            onTap: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
