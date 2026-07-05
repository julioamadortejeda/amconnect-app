/// Feature flags para habilitar/deshabilitar funcionalidades en desarrollo.
/// Cambiar a false para volver al comportamiento original.
const kVoiceChatEnabled = true;

/// Creación manual de recordatorios (CreateReminderScreen).
/// Deshabilitada para la beta: la pantalla es un mock (el guardado no crea
/// nada) — ver backlog. Los recordatorios se crean vía chat/voz de IA.
const kManualReminderCreationEnabled = false;
