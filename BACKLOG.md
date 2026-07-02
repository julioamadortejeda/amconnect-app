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
- [ ] **Optimizar consumo de tokens en Chat de Voz:** Revisar por qué el chat de voz consume una cantidad elevada de tokens en comparación con el de texto y optimizar la ventana de historial/prompts enviados.
- [ ] **Opción de conocimiento híbrido (Cliente + General):** Al subir/crear un documento de conocimiento asignado a un cliente específico, permitir marcar un toggle/checkbox para que también se indexe como conocimiento general del agente (accesible globalmente por la IA sin requerir el filtro de cliente).
- [ ] **Compartir Archivos desde el Sistema (Share Extension / Send Intent):** Permitir que cuando se comparta un documento (PDF, imagen, etc.) desde WhatsApp u otras apps en el dispositivo, aparezca AmConnect como opción para enviarlo directamente a la base de conocimiento de la aplicación.

## Limpieza de Mocks / Datos Simulados

- [ ] **Eliminar datos simulados y mocks en el cliente**
  - Conectar `CreateReminderScreen` al proveedor real de clientes (`clientsProvider`) para cargar los contactos reales de la base de datos.
  - Eliminar por completo el archivo `mock_data.dart` y asegurar que no haya referencias a datos simulados en toda la aplicación.

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
