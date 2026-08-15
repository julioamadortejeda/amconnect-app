import '../models/ai_chat_context.dart';
import '../../l10n/app_localizations.dart';

/// Texto de la burbuja inicial sintética que se muestra al abrir el chat con
/// un [AiChatContext] precargado (desde cliente, póliza, recordatorio o un
/// documento del Feed) — deja claro al asesor que puede preguntar sobre eso
/// sin tener que dar contexto. No es una respuesta real de la IA: se genera
/// localmente y nunca se envía al backend ni cuenta como turno de chat.
String buildContextSuggestion(AiChatContext context, AppLocalizations l10n) {
  switch (context.type) {
    case 'contact':
      final name = context.data['fullName'] as String?;
      return l10n.chatContextSuggestionContact(name ?? '');
    case 'policy':
      final carrier = context.data['carrierName'] as String?;
      return l10n.chatContextSuggestionPolicy(carrier ?? '');
    case 'reminder':
      final title = context.data['title'] as String?;
      return l10n.chatContextSuggestionReminder(title ?? '');
    case 'knowledge':
      final fileName = context.data['fileName'] as String?;
      return fileName != null
          ? l10n.chatContextSuggestionKnowledge(fileName)
          : l10n.chatContextSuggestionKnowledgeGeneric;
    default:
      return l10n.chatContextSuggestionKnowledgeGeneric;
  }
}
