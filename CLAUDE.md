# AMConnect Flutter App — CLAUDE.md

## Contexto del proyecto

App móvil Flutter para asesores de seguros. Permite gestionar clientes, pólizas, recordatorios y chatear con un asistente IA. Diseño basado en prototipo HTML/CSS exportado desde Claude Design.

**Stack:** Flutter · Riverpod 3.x · GoRouter · Google Fonts

---

## Estructura del proyecto

```
lib/
├── core/
│   ├── mock/
│   │   └── mock_data.dart          # Datos de prueba: clientes, pólizas, recordatorios, chat
│   ├── router/
│   │   └── router.dart             # GoRouter: shell + push routes
│   ├── shell/
│   │   └── shell_screen.dart       # Scaffold con bottom tab bar + FAB micrófono central
│   ├── theme/
│   │   ├── app_colors.dart         # Design tokens: accent #007AC0, light/dark surfaces
│   │   └── theme.dart              # MaterialApp theme (AzulProTheme)
│   └── widgets/                    # Widgets reutilizables (ver detalle abajo)
│       ├── am_avatar.dart
│       ├── am_back_bar.dart
│       ├── am_badge.dart
│       ├── am_card.dart
│       ├── am_icon_btn.dart
│       ├── am_press.dart
│       ├── am_ramo_icon.dart
│       ├── am_section_label.dart
│       ├── am_segmented.dart
│       └── am_text_field.dart      # Campo de texto estilizado (reutilizable en forms)
└── features/
    ├── onboarding/
    │   ├── presentation/
    │   │   ├── splash_screen.dart  # Logo animado con rings pulsantes → auto-navega a /login
    │   │   └── login_screen.dart   # Gradiente azul, botones Apple/Google/invitado
    │   ├── providers/
    │   │   └── login_provider.dart # LoginNotifier: signInWithGoogle/Apple/Guest/Email
    │   └── widgets/
    │       ├── login_social_btn.dart   # Botón blanco con icon + texto azul (Apple/Google)
    │       ├── login_guest_btn.dart    # Botón transparente "Explorar como invitado"
    │       └── email_login_sheet.dart  # Bottom sheet con form email/contraseña
    ├── home/presentation/
    │   └── home_screen.dart        # Dashboard del asesor: alertas, action cards, AI bar, stats
    ├── clients/presentation/
    │   ├── clients_screen.dart     # Lista con búsqueda (Riverpod)
    │   └── client_detail_screen.dart  # Perfil, tabs pólizas/notas, acciones rápidas
    ├── reminders/presentation/
    │   ├── reminders_screen.dart   # Lista con filtros chips y checkbox toggle
    │   └── create_reminder_screen.dart  # Form con selector tipo/cliente/fecha, toggle repetir
    ├── chat/presentation/
    │   └── chat_screen.dart        # Chat IA con typing dots, tarjetas de respuesta, bullets
    └── feed/presentation/
        └── feed_screen.dart        # Grid de tipos de carga + hoja de procesamiento animada
```

---

## Rutas (GoRouter)

| Path | Pantalla | Tipo |
|---|---|---|
| `/` | SplashScreen | full |
| `/login` | LoginScreen | full |
| `/home` | HomeScreen | shell tab |
| `/agenda` | RemindersScreen | shell tab |
| `/clientes` | ClientsScreen | shell tab |
| `/datos` | FeedScreen | shell tab |
| `/clientes/:id` | ClientDetailScreen | push slide |
| `/crear-recordatorio` | CreateReminderScreen | push slide |
| `/chat` | ChatScreen | push slide |

---

## Widgets reutilizables

| Widget | Props clave | Notas |
|---|---|---|
| `AmPress` | `onTap`, `scale` | Animación 0.96 escala al presionar |
| `AmCard` | `onTap`, `noPad`, `padding` | Shadow + radius 22 |
| `AmBadge` | `label`, `tone` (accent/green/red/amber/muted), `icon` | |
| `AmAvatar` | `client` (MockClient), `size`, `radius` | Iniciales + color del cliente |
| `AmIconBtn` | `icon`, `tone` (soft/sunken/accent/ghost), `dim`, `dot` | |
| `AmSegmented` | `options`, `selected`, `onSelect` | Tabs estilo iOS |
| `AmSectionLabel` | `label`, `trailing` | Label en mayúsculas |
| `AmBackBar` | `title`, `subtitle`, `trailing`, `onBack` | Blur + sticky top |
| `AmRamoIcon` | `ramo`, `size` | Icono coloreado: Auto/GMM/Vida/Hogar |

---

## Arquitectura de features

### Separación pantalla / lógica

**Las pantallas solo presentan. Toda lógica va en providers.**

- Cada feature tiene su propio provider en `features/<nombre>/providers/<nombre>_provider.dart`
- La pantalla (`presentation/`) solo hace `ref.watch` / `ref.read` + renderiza
- No hay funciones async inline en `build`, ni llamadas directas a `authProvider` u otros providers core desde la pantalla — pasan por el provider de la feature
- Los errores los decide el provider (expone un enum de error); la pantalla convierte ese enum en string para mostrarlo

### Widgets sin guión bajo — cada uno en su propio archivo

- **Nunca** clases privadas con `_` en un archivo de pantalla
- Si el widget es reutilizable en otras pantallas → `core/widgets/am_<nombre>.dart`
- Si el widget es específico de una feature → `features/<feature>/widgets/<nombre>.dart`
- Convención de nombre: `LoginSocialBtn`, `EmailLoginSheet`, `AmTextField` (sin prefijo `_`)

### Estructura de un feature completo

```
features/<nombre>/
├── presentation/
│   └── <nombre>_screen.dart    # solo UI, sin lógica
├── providers/
│   └── <nombre>_provider.dart  # NotifierProvider con toda la lógica
└── widgets/
    └── <widget_name>.dart      # un archivo por widget
```

---

## Estado con Riverpod 3.x

**IMPORTANTE:** Riverpod 3.x eliminó `StateProvider`. Usar siempre `Notifier` + `NotifierProvider`.

```dart
// Correcto en Riverpod 3.x
class MyNotifier extends Notifier<MyType> {
  @override
  MyType build() => initialValue;
  void update(MyType val) => state = val;
}
final myProvider = NotifierProvider<MyNotifier, MyType>(MyNotifier.new);

// ❌ NO usar — StateProvider fue removido en Riverpod 3.x
final myProvider = StateProvider<String>((ref) => '');
```

### Providers existentes

| Provider | Tipo | Dónde |
|---|---|---|
| `remindersProvider` | `NotifierProvider<RemindersNotifier, List<MockReminder>>` | `home_screen.dart` |
| `clientSearchProvider` | `NotifierProvider<_SearchNotifier, String>` | `clients_screen.dart` |

`RemindersNotifier` expone `.toggle(id)` para marcar hecho/pendiente. Es compartido entre HomeScreen y RemindersScreen.

---

## Design tokens (app_colors.dart)

```dart
AmColors.accent       // #007AC0 — azul principal
AmColors.inkLight     // #16212D — texto principal
AmColors.inkSoftLight // #46525F — texto secundario
AmColors.mutedLight   // #939DAA — texto terciario
AmColors.cardSunkenLight  // fondo sunken de cards
AmColors.lineLight    // #EAE7DC — bordes
AmColors.greenLight   // #0E7C42
AmColors.redLight     // #D8453F
AmColors.amberLight   // #B9791A
AmColors.accentWash   // azul claro (fondo de badges accent)
AmColors.accentInk    // azul oscuro (texto sobre fondo accent wash)
AmColors.srcDoc / srcWhatsApp / srcWave / srcImage / srcNote  // colores de fuentes
```

---

## Datos mock (mock_data.dart)

Modelos: `MockClient`, `MockPolicy`, `MockNote`, `MockReminder`, `MockMessage`, `MockMsgCard`

Datos disponibles:
- `mockClients` — 5 clientes (Mariana Torres, Javier Mendoza, Lucía García, Carlos Reyes, Sofía Ramírez)
- `mockReminders` — 5 recordatorios (renovacion/pago/llamada, con urgente y fecha)
- `mockChatThread` — hilo de chat inicial
- `mockSuggestions` — sugerencias de preguntas al asistente
- `mockStats` — `{polizas: 12, clientes: 5}`
- `clientById(id)` — función helper para buscar cliente por ID

---

## Pendientes / próximos pasos sugeridos

- [ ] Conectar con Supabase backend (ver `/Users/Development/Projects/JACATSoft/AmConnect/backend/`)
- [ ] Reemplazar mock data con llamadas reales al Edge Function `amconnect-api`
- [ ] Implementar autenticación real (Apple/Google Sign In)
- [ ] Modo oscuro (los tokens de `app_colors.dart` tienen versiones dark listas)
- [ ] Voz real en ChatScreen (actualmente solo texto)
- [ ] Subida real de archivos en FeedScreen
- [ ] Notificaciones push para recordatorios

---

## Comandos útiles

```bash
# Desde amconnect-app/amconnect/
flutter analyze          # verificar errores
flutter run              # correr en simulador/dispositivo
flutter build ios        # build iOS
```

## Assets disponibles

```
assets/logo/
├── logo.png     # logo con fondo
└── logo_t.png   # logo transparente (el que se usa en la app)
```
