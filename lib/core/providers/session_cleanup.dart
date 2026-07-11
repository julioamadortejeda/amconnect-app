import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/account/providers/account_provider.dart';
import '../../features/home/providers/home_provider.dart';
import '../../features/clients/providers/clients_provider.dart';
import '../../features/chat/providers/chat_provider.dart';
import '../../features/chat/providers/voice_chat_provider.dart';
import '../../features/chat/providers/stt_provider.dart';
import '../../features/feed/providers/knowledge_dashboard_provider.dart';
import '../../features/reminders/providers/reminders_provider.dart';

/// Limpia toda la caché de los providers con datos de usuario de forma segura.
void clearUserSessionCache(WidgetRef ref) {
  ref.invalidate(agentProfileProvider);
  ref.invalidate(subscriptionInfoProvider);
  ref.invalidate(agentNameProvider);
  ref.invalidate(remindersProvider);
  ref.invalidate(policiesCountProvider);
  ref.invalidate(clientsProvider);
  ref.invalidate(policiesProvider);
  ref.invalidate(chatProvider);
  ref.invalidate(voiceChatProvider);
  ref.invalidate(sttProvider);
  ref.invalidate(knowledgeStatsProvider);
  ref.invalidate(remindersUiProvider);
}
