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
import '../../features/clients/presentation/create_client_screen.dart';
import '../../features/home/presentation/analytics_screen.dart';
import '../../core/models/contact.dart';
import '../../features/clients/presentation/create_policy_screen.dart';
import '../../features/clients/presentation/policy_detail_screen.dart';
import '../../core/models/policy.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/reminders/presentation/create_reminder_screen.dart';
import '../../features/reminders/presentation/reminder_detail_screen.dart';
import '../../core/models/reminder.dart';
import '../../features/chat/data/chat_context.dart';
import '../../features/assistant/presentation/assistant_screen.dart';
import '../../features/assistant/providers/assistant_provider.dart' show AssistantResumeArgs;
import '../../features/feed/presentation/feed_screen.dart';
import '../../features/onboarding/presentation/email_login_screen.dart';
import '../../features/onboarding/presentation/forgot_password_screen.dart';
import '../../features/onboarding/presentation/register_screen.dart';
import '../../features/chat/presentation/voice_chat_screen.dart';
import '../../features/chat_tts/presentation/chat_tts_screen.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/catalogs/presentation/catalogs_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier(ref);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = ref.read(authUserProvider).value;
      final loc = state.matchedLocation;
      final onPublic = loc == '/' ||
          loc == '/login' ||
          loc == '/email-login' ||
          loc == '/register' ||
          loc == '/forgot-password';
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
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (_, state) => amTransitionPage(
            child: const ForgotPasswordScreen(), state: state, type: 'push'),
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
              path: '/portfolio',
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
        path: '/analytics',
        pageBuilder: (_, state) => amTransitionPage(
          child: const AnalyticsScreen(),
          state: state,
          type: 'push',
        ),
      ),
      GoRoute(
        path: '/create-client',
        pageBuilder: (_, state) => amTransitionPage(
          child: CreateClientScreen(contact: state.extra as Contact?),
          state: state,
          type: 'push',
        ),
      ),
      GoRoute(
        path: '/create-policy',
        pageBuilder: (_, state) => amTransitionPage(
          child: CreatePolicyScreen(
            clientId: state.uri.queryParameters['client'],
            policy: state.extra as Policy?,
          ),
          state: state,
          type: 'push',
        ),
      ),
      GoRoute(
        path: '/policy/:id',
        pageBuilder: (_, state) => amTransitionPage(
          child: PolicyDetailScreen(
            policy: state.extra as Policy?,
            policyId: state.pathParameters['id'],
          ),
          state: state,
          type: 'push',
        ),
      ),
      GoRoute(
        path: '/clients/:id',
        pageBuilder: (_, state) {
          final fromChat = state.uri.queryParameters['fromChat'] == 'true';
          return amTransitionPage(
            child: ClientDetailScreen(
              clientId: state.pathParameters['id'] ?? '',
              fromChat: fromChat,
            ),
            state: state,
            type: 'push',
          );
        },
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
          child: ReminderDetailScreen(
            reminder: state.extra as Reminder?,
            reminderId: state.pathParameters['id'],
          ),
          state: state,
          type: 'push',
        ),
      ),
      GoRoute(
        path: '/chat',
        pageBuilder: (_, state) {
          final extra = state.extra;
          final child = extra is AssistantResumeArgs
              ? AssistantScreen(resumeArgs: extra)
              : AssistantScreen(initialContext: extra as AiChatContext?);
          return amTransitionPage(child: child, state: state, type: 'push');
        },
      ),
      GoRoute(
        path: '/voice-chat',
        pageBuilder: (_, state) => amTransitionPage(
          child: const VoiceChatScreen(),
          state: state,
          type: 'push',
        ),
      ),
      GoRoute(
        path: '/voice-chat-tts',
        pageBuilder: (_, state) => amTransitionPage(
          child: const ChatTtsScreen(),
          state: state,
          type: 'push',
        ),
      ),
      GoRoute(
        path: '/account',
        pageBuilder: (_, state) => amTransitionPage(
          child: const AccountScreen(),
          state: state,
          type: 'push',
        ),
      ),
      GoRoute(
        path: '/catalogs',
        pageBuilder: (_, state) => amTransitionPage(
          child: const CatalogsScreen(),
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

