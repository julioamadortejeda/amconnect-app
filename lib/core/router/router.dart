import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/shell/shell_screen.dart';
import 'package:amconnect/features/onboarding/presentation/splash_screen.dart';
import 'package:amconnect/features/onboarding/presentation/login_screen.dart';
import 'package:amconnect/features/home/presentation/home_screen.dart';
import 'package:amconnect/features/clients/presentation/clients_screen.dart';
import 'package:amconnect/features/clients/presentation/client_detail_screen.dart';
import 'package:amconnect/features/reminders/presentation/reminders_screen.dart';
import 'package:amconnect/features/reminders/presentation/create_reminder_screen.dart';
import 'package:amconnect/features/chat/presentation/chat_screen.dart';
import 'package:amconnect/features/feed/presentation/feed_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

    // Shell with bottom tab bar
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

    // Push routes (full screen, no shell)
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
