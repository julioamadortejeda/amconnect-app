import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../../../core/providers/auth_provider.dart';
import '../../clients/providers/catalog_provider.dart';
import '../../home/providers/home_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Transición suave mínima desde el splash nativo
    final minDelay = Future.delayed(const Duration(milliseconds: 600));

    // 1. COMPUERTA DE SEGURIDAD: Verificamos autenticación
    User? user;
    try {
      user = await ref.read(authUserProvider.future);
    } catch (_) {
      user = ref.read(authUserProvider).value;
    }

    if (!mounted) return;

    if (user == null) {
      // Si NO hay sesión activa: ir directamente a /login sin invocar providers de datos
      await minDelay;
      if (mounted) context.go('/login');
      return;
    }

    // 2. SESIÓN ACTIVA: Precargamos los datos del Home y catálogos en segundo plano
    try {
      await Future.wait([
        minDelay,
        ref.read(homeReadyProvider.future),
        ref.read(branchesProvider.future),
      ]).timeout(const Duration(seconds: 4));
    } catch (_) {
      // Timeout o error de red: dejamos que HomeScreen gestione su ciclo normal
    }

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.primary,
      body: Center(
        child: Image.asset(
          'assets/logo/logo_white.png',
          width: 108,
          height: 108,
        ),
      ),
    );
  }
}
