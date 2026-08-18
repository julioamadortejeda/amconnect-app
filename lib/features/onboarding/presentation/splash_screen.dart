import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/pending_route_provider.dart';
import '../../../core/router/router.dart';
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

    if (!mounted) return;
    context.go('/home');

    // Si la app se abrió tocando una notificación, el destino quedó guardado en
    // vez de navegarse: el `go` de arriba habría borrado la pila. Se abre ahora,
    // encima del dashboard, para que el back regrese ahí.
    // En el MISMO frame que el `go`, no en un postFrameCallback: así GoRouter
    // arma la pila [home, detalle] de una sola vez y solo pinta el resultado.
    // Diferirlo hacía que se viera el dashboard ~300 ms y luego el detalle
    // entrando con la animación de push.
    final pending = ref.read(pendingRouteProvider.notifier).take();
    if (pending != null) {
      ref.read(routerProvider).push(pending);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo/logo_white.png',
              width: 108,
              height: 108,
            ),
            const SizedBox(height: 28),
            // Aquí NO va AmLoader: es el logo pulsando en cs.primary, que sobre
            // este fondo azul sería invisible y además duplicaría el logo de
            // arriba. El splash necesita solo la señal de que está trabajando.
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.85)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
