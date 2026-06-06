import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/core/widgets/am_text_field.dart';
import 'package:amconnect/features/onboarding/providers/login_provider.dart';

const _kBg = Color(0xFF1278C5);

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _localError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _localError = 'Ingresa tu correo y contraseña.');
      return;
    }
    setState(() => _localError = null);
    await ref.read(loginProvider.notifier).signInWithEmail(email, pass);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final serverError = state.error == LoginError.email
        ? 'Correo o contraseña incorrectos.'
        : null;
    final errorMsg = _localError ?? serverError;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AmPress(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 17),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/logo/logo.png', width: 64, height: 64),
                    const SizedBox(height: 28),
                    const Text(
                      'Entrar con\ncorreo',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ingresa tus datos para acceder a tu cuenta.',
                      style: TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          color: Colors.white.withValues(alpha: 0.80)),
                    ),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AmTextField(
                            controller: _emailCtrl,
                            hint: 'Correo electrónico',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          AmTextField(
                            controller: _passCtrl,
                            hint: 'Contraseña',
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            suffix: GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AmColors.mutedLight,
                                  size: 20,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),

                          if (errorMsg != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AmColors.redWashLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline,
                                    color: AmColors.redLight, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(errorMsg,
                                        style: const TextStyle(
                                            color: AmColors.redLight,
                                            fontSize: 13.5))),
                              ]),
                            ),
                          ],

                          const SizedBox(height: 20),
                          AmPress(
                            onTap: state.isLoading ? null : _submit,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AmColors.accent,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AmColors.accent.withValues(alpha: 0.28),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: state.isLoading
                                  ? const Center(
                                      child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white)))
                                  : const Text('Iniciar sesión',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
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
