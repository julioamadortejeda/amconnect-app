# AMConnect App — Backlog

> Sincronizado contra el código real 2026-07-23 — varios ítems marcados pendientes ya estaban resueltos y se movieron a "Completado". El backlog general y más completo del proyecto (auditado seguido) vive en `/Users/Development/Projects/JACATSoft/backlog.md` — usar ese como fuente principal; este archivo es específico de detalles a nivel app que no siempre están ahí.

## UX / Diseño

- [x] **Mejorar presentación de errores en ChatScreen** — resuelto en general por `core/utils/api_error_mapper.dart` + `error_translator.dart` (mapean `errorCode` a mensajes amigables). Último hueco cerrado 2026-07-23: `assistant_provider.dart` (chat del Assistant) tenía su propia función local `mapApiError` duplicada y rota — hacía *substring match* de `'429'`/`'Quota'`/`'límite'` sobre el texto crudo del error, así que un `AiProviderError` (503, Gemini ocupado) cuyo mensaje interpola `"(429)"` literal se mostraba como "Has alcanzado el límite de uso de tu plan actual" en vez de "El asistente está ocupado, intenta de nuevo". Se eliminó la duplicada y ahora usa la versión compartida (mismo patrón que `chat_provider.dart`/`ingest_provider.dart`/`chat_tts_provider.dart`), que sí traduce `AI_PROVIDER_BUSY` correctamente.

  Problema original: el chat mostraba el error técnico crudo como burbuja roja:
  `Error en classifyMessage: {"error":{"code":503,"message":"This model is currently experiencing high demand...","status":"UNAVAILABLE"}}`

## Auth

- [ ] **Apple Sign In — falta la capability en Xcode** (encontrado 2026-07-23): el código ya llama `sign_in_with_apple` (`login_screen.dart`, `supabase_auth_repository.dart`, `auth_provider.dart`; paquete `sign_in_with_apple: ^8.1.0` en `pubspec.yaml`), pero `ios/Runner/Runner.entitlements` no tiene la key `com.apple.developer.applesignin` y `project.pbxproj` tampoco declara la capability "Sign In with Apple". Sin esto, el login con Apple falla en dispositivo real/TestFlight aunque el código Dart esté listo. Agregar la capability desde Xcode: target Runner → Signing & Capabilities → "+ Capability" → Sign In with Apple.
- [ ] Confirmar que los providers de Google/Apple estén habilitados en el Supabase Dashboard de **producción** — mismo ítem pendiente en `backlog.md` raíz § Deploy a producción (línea "Google Sign-In en Dashboard").

## Features pendientes

- [ ] **Optimizar consumo de tokens en Chat de Voz:** Revisar por qué el chat de voz consume una cantidad elevada de tokens en comparación con el de texto y optimizar la ventana de historial/prompts enviados. El chat de **texto** ya se optimizó 2026-07-23 (implicit caching + `thinking_level: minimal`, ver `backend/BACKLOG.md` §T1-T3, bajó de ~40s a ~4s por ronda) — la voz sigue sin revisar, mismo tipo de problema es candidato ahí también.
- [ ] **Opción de conocimiento híbrido (Cliente + General):** Al subir/crear un documento de conocimiento asignado a un cliente específico, permitir marcar un toggle/checkbox para que también se indexe como conocimiento general del agente (accesible globalmente por la IA sin requerir el filtro de cliente).
- [ ] **Compartir Archivos desde el Sistema (Share Extension / Send Intent)** — mismo ítem que en `backlog.md` raíz § App Flutter → Pulido. Hoy no hay ningún paquete de deep link/share intent en `pubspec.yaml` ni intent-filters de `VIEW`/`SEND` en Android/iOS.

## Ideas de Negocio y Crecimiento Futuro (AI & Monetización)

- [ ] **Esquema de Precios SaaS de 3 Niveles (Suscripción Mensual/Anual)**
  - **Plan Rookie / Individual ($349 MXN/mes)**: Para asesores iniciales o cartera pequeña (<50 clientes, 15 ingestas/mes, 300 chats/mes, 512MB storage).
  - **Plan Pro / Crecimiento ($749 MXN/mes)**: Para asesores establecidos (40 ingestas/mes, 1,000 chats/mes, 1GB storage).
  - **Plan Despacho / Agencia ($1,499 MXN/mes)**: Para promotorías y equipos (120 ingestas/mes, 3,000 chats/mes, 5GB storage).
- [ ] **Mapeo de Add-ons y Consumos de Pago Único**
  - **Créditos de Carga Extra**: Venta de paquetes de ingesta (ej. 20 pólizas extra por $149 MXN) cuando el usuario agote su límite mensual.
  - **Cobro por Asiento Administrativo**: Cobro de $199 MXN/mes por cada usuario asistente adicional agregado a la cuenta del asesor.
  - **Integración API Oficial de WhatsApp**: Cobro adicional (ej. $199 MXN/mes + costo de envío de mensajes) para automatizar los envíos desde la app con un solo clic.
- [ ] **Sincronización Bidireccional de Calendario (Módulo Pro/Top)**
  - Permitir a los usuarios sincronizar las alertas de cobro, cumpleaños y renovaciones directamente con sus calendarios personales de Google Calendar y Outlook.
- [ ] **Link de Reserva Inteligente ("Calendly con IA")**
  - Página de reservas del asesor (`amconnect.app/carlos/agenda`).
  - Al agendar, la IA solicita automáticamente al cliente vía WhatsApp fotos de su póliza actual. La IA pre-analiza el archivo y crea la comparativa antes de la reunión.
- [ ] **Copiloto Activo de Agenda (Resumen Proactivo de la IA)**
  - Envío automático de notificaciones push o resúmenes de agenda al iniciar la semana con pólizas críticas a vencer, cotizaciones pre-fabricadas por la IA y sugerencias de retención.
- [ ] **Agenda Automatizada de Seguimiento de Siniestros**
  - Flujo de tareas interactivo sugerido por la IA en la agenda cada vez que se registre un siniestro (chocó un cliente, hospitalización), ayudando al asesor a dar seguimiento en tiempos de entrega de facturas y visitas de ajustadores.
- [ ] **WhatsApp con Plantillas Dinámicas por IA (Mensajes del Asesor)**
  - Tabla `message_templates` vinculada a `agent_id` con *placeholders* (`{{client_name}}`, `{{policy_product}}`).
  - Al pedir a la IA generar un mensaje, ésta rellena la plantilla del asesor e incorpora variaciones de tono (formal, amigable) solicitadas en el chat.
- [ ] **AI Cross-Selling Basado en Oferta Real (RAG de Planes)**
  - Permitir al asesor subir folletos y tarifas generales de aseguradoras a su base de conocimiento sin vincularlos a clientes.
  - La IA realiza una búsqueda vectorial (RAG) en esos productos para sugerir de forma específica qué planes ofrecer al cliente según las brechas detectadas.
- [ ] **Workspace de Agencia Multi-Agente (Compartición RLS)**
  - Tabla `agencies` en la base de datos y columna `agency_id` en `agents`.
  - Actualizar políticas RLS de Supabase en `contacts`, `policies`, `agent_notes` y `reminders` para permitir lectura/escritura a nivel agencia.

## Completado

- [x] i18n — ES + EN via ARB + flutter_localizations
- [x] Modo oscuro — `AzulProTheme.darkTheme` + `AmTheme` extension; todos los widgets usan `cs.*`/`context.am.*`
- [x] Home screen — refactor completo, widgets en archivos propios, floating header al hacer scroll
- [x] Shell — FAB micrófono central sin recorte, blur en tab bar
- [x] Clientes conectados a Supabase (tabla `contacts`) — lista, búsqueda, detalle, Realtime
- [x] Recordatorios conectados a Supabase (tabla `reminders`) — CRUD completo, Realtime
- [x] Google Sign-In Android — `android/app/google-services.json` presente
- [x] Voz real en ChatScreen — `VoiceOverlay` (walkie-talkie) + pantalla Live con Gemini Live API por WebSocket, audio PCM bidireccional
- [x] Subida real de archivos en FeedScreen — PDF, audio, imagen, texto y WhatsApp, los 5 tipos pegan al backend real
- [x] Notificaciones push para recordatorios — FCM v1 de punta a punta
- [x] Mocks eliminados — `mock_data.dart` ya no existe en el repo, sin referencias a datos simulados en `lib/`
