import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/features/onboarding/providers/register_provider.dart';
import 'package:amconnect/features/onboarding/widgets/auth_app_bar.dart';
import 'package:amconnect/features/onboarding/widgets/auth_divider.dart';
import 'package:amconnect/features/onboarding/widgets/auth_error_msg.dart';
import 'package:amconnect/features/onboarding/widgets/auth_field.dart';
import 'package:amconnect/features/onboarding/widgets/auth_submit_btn.dart';
import 'package:amconnect/l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  late final AnimationController _ctrl;
  late final Animation<double> _headerOpacity;
  late final Animation<double> _headerDy;
  late final Animation<double> _fieldsOpacity;
  late final Animation<double> _fieldsDy;
  late final Animation<double> _footerOpacity;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_rebuild);
    _passCtrl.addListener(_rebuild);
    _confirmCtrl.addListener(_rebuild);

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _headerOpacity =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.70, curve: Curves.easeOut),
    ));
    _headerDy = Tween<double>(begin: 14.0, end: 0.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.70, curve: Curves.easeOut),
    ));
    _fieldsOpacity =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.42, 0.85, curve: Curves.easeOut),
    ));
    _fieldsDy = Tween<double>(begin: 14.0, end: 0.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.42, 0.85, curve: Curves.easeOut),
    ));
    _footerOpacity =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.60, 1.00, curve: Curves.easeOut),
    ));

    _ctrl.forward();
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _emailCtrl.removeListener(_rebuild);
    _passCtrl.removeListener(_rebuild);
    _confirmCtrl.removeListener(_rebuild);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailCtrl.text.trim().isNotEmpty &&
      _passCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(registerProvider);

    final errorMsg = switch (state.error) {
      RegisterError.emptyFields => l10n.errFillAll,
      RegisterError.passwordMismatch => l10n.errPasswordMismatch,
      RegisterError.serverError => l10n.errCreateAccount,
      null => null,
    };

    final size = MediaQuery.sizeOf(context);
    final scale = (size.width / 390).clamp(0.80, 1.40);
    final vScale = (size.height / 844).clamp(0.75, 1.40);

    return Scaffold(
      backgroundColor: AmColors.authBg,
      appBar: const AuthAppBar(),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              28 * scale, 12 * vScale, 28 * scale, 14 * vScale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
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

              // Título + subtítulo
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) => Opacity(
                  opacity: _headerOpacity.value,
                  child: Transform.translate(
                      offset: Offset(0, _headerDy.value), child: child),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.registerTitle,
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
                      l10n.registerSubtitle,
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
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) => Opacity(
                  opacity: _fieldsOpacity.value,
                  child: Transform.translate(
                      offset: Offset(0, _fieldsDy.value), child: child),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AuthField(
                      controller: _emailCtrl,
                      hint: l10n.fieldEmail,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: 12 * vScale),
                    AuthField(
                      controller: _passCtrl,
                      hint: l10n.fieldPassword,
                      icon: Icons.lock_outline,
                      obscure: _obscurePass,
                      textInputAction: TextInputAction.next,
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        child: Icon(
                          _obscurePass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AmColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * vScale),
                    AuthField(
                      controller: _confirmCtrl,
                      hint: l10n.fieldConfirm,
                      icon: Icons.lock_outline,
                      obscure: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onSubmit(),
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        child: Icon(
                          _obscureConfirm
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
                            ref.read(registerProvider.notifier).clearError(),
                      ),
                    ],
                    SizedBox(height: 20 * vScale),
                    AuthSubmitBtn(
                      label: l10n.registerBtn,
                      enabled: _canSubmit,
                      isLoading: state.isLoading,
                      onTap: _onSubmit,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24 * vScale),

              // Footer
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) =>
                    Opacity(opacity: _footerOpacity.value, child: child),
                child: Column(
                  children: [
                    const AuthDivider(),
                    SizedBox(height: 16 * vScale),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.registerHasAccount,
                          style: TextStyle(
                            fontSize: 14 * scale,
                            color: AmColors.authSubtitle,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Text(
                            l10n.registerSignIn,
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w700,
                              color: AmColors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: AmColors.white,
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
    );
  }

  void _onSubmit() => ref
      .read(registerProvider.notifier)
      .signUp(_emailCtrl.text.trim(), _passCtrl.text, _confirmCtrl.text);
}
