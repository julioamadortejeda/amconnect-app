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
import '../../features/reminders/presentation/reminder_detail_screen.dart';
import '../../core/models/reminder.dart';
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
      GoRoute(
        path: '/',
        pageBuilder: (_, state) => amTransitionPage(child: const SplashScreen(), state: state, type: 'fade'),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) => amTransitionPage(child: const LoginScreen(), state: state, type: 'fade'),
      ),
      GoRoute(
        path: '/email-login',
        pageBuilder: (_, state) => amTransitionPage(child: const EmailLoginScreen(), state: state, type: 'push'),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, state) => amTransitionPage(child: const RegisterScreen(), state: state, type: 'push'),
      ),

      ShellRoute(
        builder: (context, state, child) =>
            ShellScreen(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, state) => amTransitionPage(child: const HomeScreen(), state: state, type: 'fade'),
          ),
          GoRoute(
            path: '/reminders',
            pageBuilder: (_, state) => amTransitionPage(child: const RemindersScreen(), state: state, type: 'fade'),
          ),
          GoRoute(
            path: '/clients',
            pageBuilder: (_, state) => amTransitionPage(child: const ClientsScreen(), state: state, type: 'fade'),
          ),
          GoRoute(
            path: '/data',
            pageBuilder: (_, state) => amTransitionPage(child: const FeedScreen(), state: state, type: 'fade'),
          ),
        ],
      ),

      GoRoute(
        path: '/clients/:id',
        pageBuilder: (_, state) => amTransitionPage(
          child: ClientDetailScreen(clientId: state.pathParameters['id'] ?? ''),
          state: state,
          type: 'push',
        ),
      ),
      GoRoute(
        path: '/create-reminder',
        pageBuilder: (_, state) => amTransitionPage(
          child: CreateReminderScreen(clienteId: state.uri.queryParameters['cliente']),
          state: state,
          type: 'push',
        ),
      ),
      GoRoute(
        path: '/reminder/:id',
        pageBuilder: (_, state) => amTransitionPage(
          child: ReminderDetailScreen(reminder: state.extra as Reminder),
          state: state,
          type: 'push',
        ),
      ),
      GoRoute(
        path: '/chat',
        pageBuilder: (_, state) => amTransitionPage(child: const ChatScreen(), state: state, type: 'push'),
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

CustomTransitionPage<T> amTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
  required String type, // 'push' | 'pop' | 'fade'
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 420),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.of(context).disableAnimations) {
        return child;
      }

      switch (type) {
        case 'push':
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final opacity = animation.value;
              final dx = (1.0 - Curves.easeOutCubic.transform(animation.value)) * 34.0;
              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                ),
              );
            },
            child: child,
          );
        case 'pop':
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final opacity = animation.value;
              final dx = -(1.0 - Curves.easeOutCubic.transform(animation.value)) * 34.0;
              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                ),
              );
            },
            child: child,
          );
        case 'fade':
        default:
          return FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.ease)),
            child: child,
          );
      }
    },
  );
}

