import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/email_login_provider.dart';
import '../widgets/auth_app_bar.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_error_msg.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_submit_btn.dart';
import '../../../core/widgets/am_fade_animation.dart';
import '../../../l10n/app_localizations.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _emailTouched = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_onEmailChanged);
    _passCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});
  void _onEmailChanged() => setState(() => _emailTouched = false);

  @override
  void dispose() {
    _emailCtrl.removeListener(_onEmailChanged);
    _passCtrl.removeListener(_rebuild);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(emailLoginProvider);

    final email = _emailCtrl.text.trim();
    final isEmailEmpty = email.isEmpty;
    final isEmailValid = isEmailEmpty ||
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

    final String? validationError =
        (_emailTouched && !isEmailValid) ? l10n.errInvalidEmail : null;
    final errorMsg = validationError ??
        (switch (state.error) {
          EmailLoginError.emptyFields => l10n.errEmptyCredentials,
          EmailLoginError.wrongCredentials => l10n.errWrongCredentials,
          null => null,
        });

    final size = MediaQuery.sizeOf(context);
    final scale = (size.width / 390).clamp(0.80, 1.40);
    final vScale = (size.height / 844).clamp(0.75, 1.40);

    final isFormValid = _emailCtrl.text.trim().isNotEmpty &&
        _passCtrl.text.isNotEmpty &&
        isEmailValid;

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
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          28 * scale, 12 * vScale, 28 * scale, 14 * vScale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo animado con Hero
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
          
                          // Título + subtítulo reutilizando la animación Fade
                          AmFadeAnimation(
                            delayMs: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.emailLoginTitle,
                                  style: TextStyle(
                                    fontSize: 38 * scale,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -1.0,
                                    height: 1.05,
                                  ),
                                ),
                                SizedBox(height: 8 * vScale),
                                Text(
                                  l10n.emailLoginSubtitle,
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
  
                  // Campos + botón
                  AmFadeAnimation(
                  delayMs: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AuthField(
                        controller: _emailCtrl,
                        hint: l10n.fieldEmail,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onBlur: () => setState(() => _emailTouched = true),
                      ),
                      SizedBox(height: 12 * vScale),
                      AuthField(
                        controller: _passCtrl,
                        hint: l10n.fieldPassword,
                        icon: Icons.lock_outline,
                        obscure: _obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => isFormValid ? _onSubmit() : null,
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AmColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(height: 8 * vScale),
                      Text(
                        l10n.emailLoginForgot,
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: AmColors.authSubtitle,
                        ),
                      ),
                      if (errorMsg != null) ...[
                        SizedBox(height: 10 * vScale),
                        AuthErrorMsg(
                          message: errorMsg,
                          scale: scale,
                          onDismiss: () {
                            setState(() => _emailTouched = false);
                            ref.read(emailLoginProvider.notifier).clearError();
                          },
                        ),
                      ],
                      SizedBox(height: 20 * vScale),
                      AuthSubmitBtn(
                        label: l10n.emailLoginBtn,
                        enabled: isFormValid,
                        isLoading: state.isLoading,
                        onTap: _onSubmit,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24 * vScale),

                // Footer
                AmFadeAnimation(
                  delayMs: 400,
                  child: Column(
                    children: [
                      const AuthDivider(),
                      SizedBox(height: 16 * vScale),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.emailLoginNoAccount,
                            style: TextStyle(
                              fontSize: 14 * scale,
                              color: AmColors.authSubtitle,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: Text(
                              l10n.emailLoginCreateAccount,
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14 * vScale),
                      Text(
                        l10n.commonTerms,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: AmColors.authSubtitle,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1 * vScale),
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

  void _onSubmit() => ref
      .read(emailLoginProvider.notifier)
      .signIn(_emailCtrl.text.trim(), _passCtrl.text);
}
