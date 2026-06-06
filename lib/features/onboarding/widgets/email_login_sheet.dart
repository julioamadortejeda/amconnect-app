import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/core/widgets/am_text_field.dart';
import 'package:amconnect/features/onboarding/providers/login_provider.dart';

class EmailLoginSheet extends ConsumerStatefulWidget {
  const EmailLoginSheet({super.key});

  @override
  ConsumerState<EmailLoginSheet> createState() => _EmailLoginSheetState();
}

class _EmailLoginSheetState extends ConsumerState<EmailLoginSheet> {
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
    if (!mounted) return;
    if (ref.read(loginProvider).error == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final serverError = state.error == LoginError.email
        ? 'Correo o contraseña incorrectos.'
        : null;
    final errorMsg = _localError ?? serverError;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AmColors.lineLight,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          const Text('Entrar con correo',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AmColors.inkLight,
                  letterSpacing: -0.01)),
          const SizedBox(height: 20),

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
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AmColors.redWashLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AmColors.redLight, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(errorMsg,
                        style: const TextStyle(color: AmColors.redLight, fontSize: 13.5))),
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
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(
                  color: AmColors.accent.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                )],
              ),
              child: state.isLoading
                  ? const Center(
                      child: SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
                  : const Text('Iniciar sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
