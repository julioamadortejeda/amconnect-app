import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/account/providers/account_provider.dart';
import '../../features/assistant/providers/assistant_provider.dart';
import '../../features/clients/providers/catalog_provider.dart';
import '../../features/clients/providers/clients_provider.dart';
import '../../features/feed/providers/knowledge_dashboard_provider.dart';
import '../../features/reminders/providers/reminder_settings_provider.dart';
import 'commitments_provider.dart';
import '../../features/home/providers/home_provider.dart';
import '../../features/reminders/providers/reminders_provider.dart';

/// Limpia toda la caché de los providers con datos de usuario de forma segura.
///
/// Mantener sincronizado con los providers `Notifier`/`AsyncNotifier`/
/// `FutureProvider`/`.family` que guardan datos del agente autenticado —
/// cualquiera que no esté aquí sobrevive al logout y se muestra tal cual
/// para el siguiente usuario que inicie sesión en el mismo dispositivo.
/// No hace falta listar providers derivados (`Provider<T>` que solo hacen
/// `ref.watch` de otros ya invalidados aquí, ej. `homeDashboardProvider`,
/// `filteredRemindersProvider`) ni los `autoDispose` — se recalculan solos.
///
/// **Sin excepción: todo `AsyncNotifier` que abra un canal de Realtime va aquí.**
/// No es solo caché: el canal queda suscrito con el `agent_id` del asesor que
/// se fue. Para cruzarlo rápido:
/// `grep -rn "\.channel(" lib/` contra esta lista.
void clearUserSessionCache(WidgetRef ref) {
  // Cuenta / perfil
  ref.invalidate(agentProfileProvider);
  ref.invalidate(subscriptionInfoProvider);
  ref.invalidate(agentNameProvider);
  ref.invalidate(homeReadyProvider);
  ref.invalidate(contactsCountProvider);

  // Recordatorios
  ref.invalidate(remindersProvider);
  ref.invalidate(remindersUiProvider);
  ref.invalidate(reminderNotesProvider);
  ref.invalidate(reminderSettingsProvider);
  ref.invalidate(policyRemindersProvider);

  // Compromisos — `commitmentsProvider` además mantiene un canal de Realtime
  // abierto (`commitments:$userId`). Sin invalidarlo, el canal sobrevivía al
  // logout filtrando por el agent_id del asesor ANTERIOR, y el siguiente que
  // entrara en ese teléfono veía los compromisos del otro.
  ref.invalidate(commitmentsProvider);

  // Clientes / pólizas
  ref.invalidate(clientsProvider);
  ref.invalidate(policiesProvider);
  ref.invalidate(policiesCountProvider);
  ref.invalidate(clientsPageInfoProvider);
  ref.invalidate(policiesPageInfoProvider);
  ref.invalidate(contactDetailProvider);
  ref.invalidate(contactNotesProvider);
  ref.invalidate(contactPoliciesProvider);
  ref.invalidate(policyNotesProvider);

  // Catálogos por agente (carriers/branches/products — a diferencia de
  // statuses/currencies/frequencies/methods, que son globales y no dependen
  // del agente)
  ref.invalidate(carriersProvider);
  ref.invalidate(branchesProvider);
  ref.invalidate(productsProvider);

  // Base de conocimiento (Feed)
  ref.invalidate(knowledgeStatsProvider);
  ref.invalidate(knowledgeListProvider);

  // Chat / voz
  ref.invalidate(assistantProvider);
}
