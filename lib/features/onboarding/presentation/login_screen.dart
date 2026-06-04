import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/widgets/am_press.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2EB0FF), Color(0xFF007AC0), Color(0xFF005580)],
            stops: [0.0, 0.50, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Logo
                Image.asset('assets/logo/logo_t.png', width: 92, height: 92,
                    color: Colors.white),
                const Spacer(),
                // Headline
                const Text(
                  'Bienvenido a\nAMConnect',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.02,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu asistente inteligente. Concentra a tus clientes, pólizas y recordatorios — y pregúntale lo que sea.',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const Spacer(),
                // Buttons
                _SocialBtn(
                  icon: Icons.apple,
                  label: 'Continuar con Apple',
                  onTap: () => context.go('/home'),
                ),
                const SizedBox(height: 13),
                _SocialBtn(
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Continuar con Google',
                  onTap: () => context.go('/home'),
                ),
                const SizedBox(height: 13),
                AmPress(
                  onTap: () => context.go('/home'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline, size: 19, color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(width: 10),
                        Text('Explorar como invitado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Al continuar, aceptas los Términos y la Política de Privacidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  const _SocialBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AmPress(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF007AC0)),
            const SizedBox(width: 11),
            Text(label,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF007AC0),
                )),
          ],
        ),
      ),
    );
  }
}
