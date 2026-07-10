/// Feature flags para habilitar/deshabilitar funcionalidades en desarrollo.
/// Cambiar a false para volver al comportamiento original.
const kVoiceChatEnabled = true;

/// Badge Free/Enterprise en las pantallas de chat/voz según el backend de IA
/// (AI_BACKEND del servidor) que procesó la última respuesta. Hoy es un
/// indicador de pruebas; decidir antes de beta si el asesor debe verlo.
const kShowAiBackendBadge = true;

/// Creación manual de recordatorios (CreateReminderScreen).
/// Deshabilitada para la beta: la pantalla es un mock (el guardado no crea
/// nada) — ver backlog. Los recordatorios se crean vía chat/voz de IA.
const kManualReminderCreationEnabled = false;
