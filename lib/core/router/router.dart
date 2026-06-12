import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shell/shell_screen.dart';
import '../providers/auth_provider.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/clients/presentation/clients_screen.dart';
import '../../features/clients/presentation/client_detail_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/reminders/presentation/create_reminder_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/feed/presentation/feed_screen.dart';
import '../../features/onboarding/presentation/email_login_screen.dart';
import '../../features/onboarding/presentation/register_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier(ref);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = ref.read(authUserProvider).value;
      final loc = state.matchedLocation;
      final onPublic = loc == '/' || loc == '/login' || loc == '/email-login' || loc == '/register';
      if (user == null && !onPublic) return '/login';
      if (user != null && onPublic) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/email-login',
        pageBuilder: (_, state) => _slide(const EmailLoginScreen(), state),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, state) => _slide(const RegisterScreen(), state),
      ),

      ShellRoute(
        builder: (context, state, child) =>
            ShellScreen(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/agenda',   builder: (_, __) => const RemindersScreen()),
          GoRoute(path: '/clientes', builder: (_, __) => const ClientsScreen()),
          GoRoute(path: '/datos',    builder: (_, __) => const FeedScreen()),
        ],
      ),

      GoRoute(
        path: '/clientes/:id',
        pageBuilder: (_, state) => _slide(
          ClientDetailScreen(clientId: state.pathParameters['id'] ?? ''),
          state,
        ),
      ),
      GoRoute(
        path: '/crear-recordatorio',
        pageBuilder: (_, state) => _slide(
          CreateReminderScreen(clienteId: state.uri.queryParameters['cliente']),
          state,
        ),
      ),
      GoRoute(
        path: '/chat',
        pageBuilder: (_, state) => _slide(const ChatScreen(), state),
      ),
    ],
  );
});

// Notifier que hace refresh al router cuando cambia el estado de auth
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authUserProvider, (_, __) => notifyListeners());
  }
}

CustomTransitionPage<void> _slide(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, _, child) => SlideTransition(
      position: animation.drive(
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
      ),
      child: child,
    ),
  );
}
