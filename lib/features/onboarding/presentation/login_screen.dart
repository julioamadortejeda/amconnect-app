import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/features/onboarding/providers/login_provider.dart';
import 'package:amconnect/features/onboarding/widgets/login_social_btn.dart';
import 'package:amconnect/features/onboarding/widgets/login_email_btn.dart';

const _kBg = Color(0xFF1278C5);

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginProvider);
    final notifier = ref.read(loginProvider.notifier);

    ref.listen(loginProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        final msg = switch (next.error!) {
          LoginError.google => 'No se pudo iniciar sesión con Google.',
          LoginError.apple  => 'No se pudo iniciar sesión con Apple.',
          LoginError.email  => 'Correo o contraseña incorrectos.',
        };
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AmColors.redLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    });

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Image.asset('assets/logo/logo.png', width: 72, height: 72),
              const Spacer(),
              const Text(
                'Bienvenido a\nAMConnect',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tu asistente inteligente. Concentra a tus clientes, pólizas y recordatorios — y pregúntale lo que sea.',
                style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: Colors.white.withValues(alpha: 0.80)),
              ),
              const Spacer(),

              if (Platform.isIOS) ...[
                LoginSocialBtn(
                  onTap: state.isLoading ? null : notifier.signInWithApple,
                  icon: const Icon(Icons.apple, size: 22, color: Color(0xFF1A1A1A)),
                  label: 'Continuar con Apple',
                ),
                const SizedBox(height: 10),
              ],

              LoginSocialBtn(
                onTap: state.isLoading ? null : notifier.signInWithGoogle,
                icon: Image.asset('assets/google_logo.png', width: 20, height: 20),
                label: 'Continuar con Google',
              ),
              const SizedBox(height: 10),

              LoginEmailBtn(
                onTap: state.isLoading ? null : () => context.push('/email-login'),
              ),

              const SizedBox(height: 20),
              Text(
                'Al continuar, aceptas los Términos y la Política de Privacidad.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.65),
                    height: 1.5),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
