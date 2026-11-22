// Feature flags para habilitar/deshabilitar funcionalidades en desarrollo.
// Cambiar a false para volver al comportamiento original.

/// Badge Free/Enterprise en las pantallas de chat/voz según el backend de IA
/// (AI_BACKEND del servidor) que procesó la última respuesta. Hoy es un
/// indicador de pruebas; decidir antes de beta si el asesor debe verlo.
const kShowAiBackendBadge = true;

/// Creación manual de recordatorios (CreateReminderScreen).
/// Alternativa a crear recordatorios vía chat/voz de IA — pantalla real,
/// conectada a POST /reminders.
const kManualReminderCreationEnabled = true;

/// Chat de texto del asistente por streaming (`POST /ai/chat/stream`, SSE):
/// muestra "buscando cliente…" y el texto mientras llega. En `false` se usa
/// solo el endpoint JSON `POST /ai/chat` (comportamiento anterior). Si el
/// stream no logra conectar, la app cae sola al JSON aunque esté en `true`.
const kAssistantStreamingEnabled = true;
