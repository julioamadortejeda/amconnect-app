import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shell/shell_screen.dart';
import '../providers/auth_provider.dart';
import '../theme/app_animations.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/clients/presentation/clients_screen.dart';
import '../../features/clients/presentation/client_detail_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/reminders/presentation/create_reminder_screen.dart';
import '../../features/reminders/presentation/reminder_detail_screen.dart';
import '../../core/models/reminder.dart';
import '../../features/chat/data/chat_context.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/feed/presentation/feed_screen.dart';
import '../../features/onboarding/presentation/email_login_screen.dart';
import '../../features/onboarding/presentation/register_screen.dart';
import '../../features/chat/presentation/voice_chat_screen.dart';

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

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (_, state) => const NoTransitionPage(child: HomeScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/reminders',
              pageBuilder: (_, state) => const NoTransitionPage(child: RemindersScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/clients',
              pageBuilder: (_, state) => const NoTransitionPage(child: ClientsScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/data',
              pageBuilder: (_, state) => const NoTransitionPage(child: FeedScreen()),
            ),
          ]),
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
        pageBuilder: (_, state) => amTransitionPage(
          child: ChatScreen(initialContext: state.extra as AiChatContext?),
          state: state,
          type: 'push',
        ),
      ),
      GoRoute(
        path: '/voice-chat',
        pageBuilder: (_, state) => amTransitionPage(
          child: const VoiceChatScreen(),
          state: state,
          type: 'push',
        ),
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

Page<T> amTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
  required String type, // 'push' | 'pop' | 'fade'
}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPage<T>(
      key: state.pageKey,
      child: child,
    );
  }

  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AmAnims.transitionDuration,
    reverseTransitionDuration: AmAnims.transitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.of(context).disableAnimations) {
        return child;
      }

      if (type == 'fade') {
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: AmAnims.fadeCurve)),
          child: child,
        );
      }

      // Slide transition: slides in from right to left, and slides out from left to right.
      return SlideTransition(
        position: animation.drive(
          Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: AmAnims.transitionCurve)),
        ),
        child: child,
      );
    },
  );
}

