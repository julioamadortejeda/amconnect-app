import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/clients/providers/clients_provider.dart';
import '../../features/feed/presentation/feed_screen.dart' show recentFeedProvider;
import '../../features/feed/providers/knowledge_dashboard_provider.dart';
import '../../features/home/providers/home_provider.dart';
import '../../features/reminders/providers/reminders_provider.dart';

/// Workaround para un bug de flutter_riverpod 3.3.2 (última versión a hoy):
/// Riverpod pausa las suscripciones de widgets ocultos (tabs inactivos del
/// IndexedStack, rutas cubiertas) vía TickerMode. Si un provider cambia o se
/// invalida mientras TODAS sus suscripciones están pausadas, el rebuild queda
/// pendiente hasta el resume — y el resume ocurre DENTRO del build del frame
/// en que el tab vuelve a ser visible (didChangeDependencies de TickerMode).
/// Cualquier provider derivado que reaccione en ese momento dispara
/// scheduleRefresh → setState() durante build → crash
/// "setState() or markNeedsBuild() called during build" y el provider queda
/// en error (ej. "Error al cargar clientes" tras una ingesta de póliza).
///
/// Este widget vive en ShellScreen FUERA del IndexedStack (siempre visible),
/// así que sus ref.listen nunca se pausan: mantienen activos los providers
/// compartidos entre tabs y sus derivados, garantizando que todo rebuild
/// ocurra en el momento del cambio (fuera de build) y nunca quede diferido
/// a un resume. Eliminar cuando riverpod corrija el resume-during-build.
class ProviderKeepAlive extends ConsumerWidget {
  const ProviderKeepAlive({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fuentes async con Realtime y/o invalidadas por el flujo de ingesta.
    ref.listen(clientsProvider, (_, __) {});
    ref.listen(policiesProvider, (_, __) {});
    ref.listen(remindersProvider, (_, __) {});
    ref.listen(policiesCountProvider, (_, __) {});
    ref.listen(recentFeedProvider, (_, __) {});
    ref.listen(knowledgeListProvider, (_, __) {});
    ref.listen(knowledgeStatsProvider, (_, __) {});
    // Derivados síncronos de las fuentes anteriores — también deben quedar
    // activos, o serían ellos los que reaccionan tarde durante el resume.
    ref.listen(homeDashboardProvider, (_, __) {});
    ref.listen(homeReadyProvider, (_, __) {});
    ref.listen(filteredRemindersProvider, (_, __) {});
    ref.listen(selectedDayRemindersProvider, (_, __) {});
    ref.listen(remindersByDateProvider, (_, __) {});
    return const SizedBox.shrink();
  }
}
