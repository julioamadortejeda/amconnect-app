import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/notification_service.dart';
import 'core/config/env.dart';
import 'core/utils/device_timezone.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'l10n/app_localizations.dart';
import 'core/providers/session_cleanup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inter viene empaquetada en assets/google_fonts/ — nunca descargar fuentes
  // en runtime (evita jank en el primer frame y dependencia de red al abrir).
  GoogleFonts.config.allowRuntimeFetching = false;
  await dotenv.load(fileName: '.env');
  await DeviceTimezone.init();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey, // ignore: deprecated_member_use
  );
  await _initCrashReporting();
  runApp(ProviderScope(
    observers: [_ProviderErrorLogger()],
    child: const MyApp(),
  ));
}

/// Inicializa Firebase antes de `runApp` (no solo tras login, como hace
/// NotificationService) para que Crashlytics capture errores desde la
/// primera pantalla. Tolerante a fallos si Firebase no está configurado.
Future<void> _initCrashReporting() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('[crash-reporting] No se pudo inicializar Firebase Crashlytics: $e');
  }
}

/// Las pantallas muestran errores localizados sin detalle y ApiClient no
/// loggea — sin esto, un provider en AsyncError es invisible en consola.
final class _ProviderErrorLogger extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('[provider-error] ${context.provider} failed: $error\n$stackTrace');
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Riverpod provider failed: ${context.provider}',
      );
    } catch (_) {
      // Crashlytics no disponible (Firebase sin configurar) — ya quedó el debugPrint.
    }
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar el estado de autenticación para registrar tokens e invalidar cachés
    ref.listen(authUserProvider, (previous, next) {
      final prevUser = previous?.value;
      final nextUser = next.value;

      // Si el ID de usuario cambia (login, logout, o cambio de cuenta), limpiamos la caché
      if (prevUser?.id != nextUser?.id) {
        clearUserSessionCache(ref);
      }

      if (nextUser != null) {
        final notificationService = ref.read(notificationServiceProvider);
        notificationService.init().then((_) {
          notificationService.requestPermissionsAndRegister();
        });
      }
    });

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AzulProTheme.lightTheme,
      darkTheme: AzulProTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      scrollBehavior: const _BouncingScrollBehavior(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

class _BouncingScrollBehavior extends MaterialScrollBehavior {
  const _BouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
