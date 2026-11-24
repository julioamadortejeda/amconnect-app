import '../../../l10n/app_localizations.dart';

/// Nombre técnico de herramienta -> texto de estado en el idioma de la app.
/// Sin nombre se usa [fallbackLabel] (del backend, backends viejos); con un
/// nombre desconocido, el genérico "Trabajando…".
String resolveToolLabel(
  AppLocalizations l10n,
  String? name,
  String? fallbackLabel,
) {
  if (name == null || name.isEmpty) {
    return (fallbackLabel == null || fallbackLabel.isEmpty)
        ? l10n.chatToolWorking
        : fallbackLabel;
  }
  switch (name) {
    case 'search_contact':
    case 'get_contact':
      return l10n.chatToolContactLookup;
    case 'create_contact':
    case 'update_contact':
      return l10n.chatToolContactSave;
    case 'search_policies':
    case 'find_policy_by_client':
    case 'get_contact_policies':
    case 'get_expiring_policies':
      return l10n.chatToolPolicies;
    case 'get_upcoming_reminders':
    case 'search_reminders':
      return l10n.chatToolSchedule;
    case 'create_reminder':
    case 'create_reminder_for_client':
      return l10n.chatToolReminderCreate;
    case 'reschedule_reminder':
      return l10n.chatToolReminderMove;
    case 'update_reminder':
    case 'mark_reminder_done':
      return l10n.chatToolReminderUpdate;
    case 'get_commitments':
      return l10n.chatToolCommitmentsCheck;
    case 'create_commitment':
      return l10n.chatToolCommitmentSave;
    case 'search_knowledge':
    case 'recall':
      return l10n.chatToolNotes;
    default:
      return l10n.chatToolWorking;
  }
}
