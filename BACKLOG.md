# AMConnect App — Backlog

## UX / Diseño

- [ ] **Mejorar presentación de errores en ChatScreen**
  El chat actualmente muestra el error técnico crudo como burbuja roja:
  `Error en classifyMessage: {"error":{"code":503,"message":"This model is currently experiencing high demand...","status":"UNAVAILABLE"}}`
  
  Lo que hay que hacer:
  - En `chat_provider.dart` (o donde se atrapa el error), parsear el mensaje antes de exponer al estado. Si contiene JSON, extraer solo el `message` interno. Si es un error de red/timeout, mostrar un mensaje genérico.
  - Mapear códigos conocidos: 503 → "El asistente está ocupado, intenta en un momento.", 401 → "Sesión expirada, vuelve a iniciar sesión.", etc.
  - La burbuja de error en `chat_screen.dart` puede quedarse igual (roja con ícono), pero el texto debe ser amigable, sin JSON ni stack traces.
  - Opcional: agregar botón "Reintentar" en la burbuja de error.

## Backend / Conectividad

- [ ] Conectar clientes con Supabase (tabla `contacts`)
- [ ] Conectar recordatorios con Supabase (tabla `reminders`)

## Auth

- [ ] Configurar Google/Apple providers en Supabase Dashboard + `supabase/config.toml`
- [ ] Agregar `google-services.json` en `android/app/` para Google Sign In Android
- [ ] Agregar capability Sign In with Apple en Xcode para Apple Sign In iOS

## Features pendientes

- [ ] Voz real en ChatScreen (actualmente solo texto)
- [ ] Subida real de archivos en FeedScreen
- [ ] Notificaciones push para recordatorios

## Limpieza de Mocks / Datos Simulados

- [ ] **Eliminar datos simulados y mocks en el cliente**
  - Conectar `CreateReminderScreen` al proveedor real de clientes (`clientsProvider`) para cargar los contactos reales de la base de datos.
  - Eliminar por completo el archivo `mock_data.dart` y asegurar que no haya referencias a datos simulados en toda la aplicación.

## Ideas de Negocio y Crecimiento Futuro (AI & Monetización)

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
