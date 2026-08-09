# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Asesores de seguros que gestionan su cartera de clientes desde el celular: dan de alta clientes y pólizas, agendan y dan seguimiento a recordatorios (renovaciones, pagos, llamadas), y consultan una base de conocimiento propia mientras están en campo o entre citas.

## Product Purpose

AmConnect es la app móvil de gestión para asesores de seguros: centraliza clientes, pólizas y recordatorios, y agrega un asistente de IA (texto y voz) que entiende ese contexto para responder y actuar sobre él. Éxito = el asesor resuelve su día (alta, seguimiento, consulta) sin salir de la app y sin fricción para llegar al dato o a la acción.

## Positioning

El diferenciador frente a otros CRMs de seguros es el asistente IA integrado (chat + voz vía Gemini Live) que opera con el contexto real del asesor — sus clientes, pólizas y recordatorios — en vez de ser un chatbot genérico desconectado de los datos.

## Operating Context

- Trabajo en campo / entre citas, mayormente con una mano, atención dividida.
- Backend: Supabase Edge Function (`amconnect-api`), Realtime para contactos/pólizas/recordatorios/notas.
- Voz en vivo vía WebSocket (Gemini Live API), con transcripción visible.
- Share target: recibe archivos/texto compartidos desde otras apps para dar de alta pólizas, clientes, recordatorios o conocimiento.

## Capabilities and Constraints

- Stack: Flutter, Riverpod 3.x, GoRouter, flutter_localizations (ARB) — sin dependencias de i18n externas.
- Soft-delete en todo: `is_active = false` + `deleted_at`, nunca DELETE físico.
- Un solo lenguaje visual (Material Design 3) en iOS y Android — el Cupertino presente en el código es puntual (action sheets/dialogs), no un tema adaptado por SO.
- Sistema de color adaptativo (light/dark) vía `ColorScheme` + tokens propios (`AmColors`, `context.am`); nunca colores fijos hardcodeados.
- Errores de API mostrados solo vía `error_translator.dart` (código conocido → string localizada; desconocido → mensaje del backend tal cual).

## Brand Commitments

Diseño basado en un prototipo HTML/CSS exportado desde Claude Design (evidencia visual incumbente, no un mundo visual a inventar). Logo en `assets/logo/` (`logo.png`, `logo_t.png`).

## Evidence on Hand

- Design system ya implementado: tokens de color (`app_colors.dart`, `am_theme.dart`), tipografía (Google Fonts), espaciado (`AmDimens`), y una librería de widgets reutilizables en `core/widgets/` (AmCard, AmTopBar, AmBadge, AmAvatar, etc.).
- Sin evidencia de assets de marca adicionales (colores oficiales fuera del código, guidelines) más allá de lo ya presente en el repo.

## Product Principles

- El asesor no debe salir de la app para resolver su día: datos y acciones (clientes, pólizas, recordatorios) están a un tap.
- El asistente IA opera con contexto real, no genérico — cada pantalla puede pasarle `AiChatContext`.
- Un solo lenguaje visual (Material) consistente en toda la app; el detalle de marca vive en el theming, no en romper patrones de plataforma.
- Estados de carga/error/vacío siempre explícitos y localizados — nunca placeholders silenciosos.

## Accessibility & Inclusion

Sin requisito normativo o de accesibilidad específico más allá de las buenas prácticas estándar de Material (contraste, touch targets ≥48dp, soporte de Dynamic Type/sp).
