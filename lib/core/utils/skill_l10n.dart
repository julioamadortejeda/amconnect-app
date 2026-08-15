import '../../l10n/app_localizations.dart';

/// Traduce el nombre técnico de una skill (tal como la declara el backend
/// para function calling, ej. "search_contact") a un texto humano — mismo
/// patrón que [CatalogL10n] para códigos de catálogo. Nunca se debe mostrar
/// el nombre crudo de una skill al usuario.
extension SkillL10n on AppLocalizations {
  String skillActivity(String skillName) => {
        // Contactos
        'search_contact': voiceSkillSearchingContacts,
        'get_contact': voiceSkillSearchingContacts,
        'get_all_contacts': voiceSkillReviewingContacts,
        'count_contacts': voiceSkillReviewingContacts,
        'create_contact': voiceSkillSavingContact,
        'update_contact': voiceSkillSavingContact,
        'delete_contact': voiceSkillSavingContact,
        'search_contact_notes': voiceSkillSearchingNotes,
        'add_note_to_client': voiceSkillSavingNote,

        // Pólizas
        'search_policies': voiceSkillSearchingPolicies,
        'get_policy': voiceSkillSearchingPolicies,
        'find_policy_by_client': voiceSkillSearchingPolicies,
        'get_all_policies': voiceSkillReviewingPolicies,
        'get_contact_policies': voiceSkillReviewingPolicies,
        'get_expiring_policies': voiceSkillReviewingPolicies,
        'get_portfolio_stats': voiceSkillReviewingPolicies,
        'count_policies': voiceSkillReviewingPolicies,
        'search_policy_notes': voiceSkillSearchingNotes,
        'create_policy': voiceSkillSavingPolicy,
        'update_policy': voiceSkillSavingPolicy,

        // Recordatorios
        'get_upcoming_reminders': voiceSkillSearchingReminders,
        'search_reminders': voiceSkillSearchingReminders,
        'create_reminder': voiceSkillSavingReminder,
        'create_reminder_for_client': voiceSkillSavingReminder,
        'update_reminder': voiceSkillSavingReminder,
        'mark_reminder_done': voiceSkillSavingReminder,
        'delete_reminder': voiceSkillSavingReminder,
        'get_reminder_statuses': voiceSkillCatalog,
        'get_reminder_types': voiceSkillCatalog,

        // Catálogo (aseguradoras, ramos, productos)
        'search_carrier': voiceSkillCatalog,
        'search_branch': voiceSkillCatalog,
        'search_product': voiceSkillCatalog,
        'get_products': voiceSkillCatalog,
        'create_carrier': voiceSkillSavingCatalog,
        'create_branch': voiceSkillSavingCatalog,
        'create_product': voiceSkillSavingCatalog,
        'update_carrier': voiceSkillSavingCatalog,
        'update_branch': voiceSkillSavingCatalog,
        'update_product': voiceSkillSavingCatalog,

        // Conocimiento / tareas pendientes
        'search_knowledge': voiceSkillKnowledge,
        'save_pending_task': voiceSkillPendingTask,
        'resolve_pending_task': voiceSkillPendingTask,
      }[skillName] ??
      voiceChatSkillActive; // fallback genérico si aparece una skill nueva sin mapear
}
