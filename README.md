# AMConnect

App móvil para asesores de seguros que centraliza clientes, pólizas y recordatorios, y permite consultar información mediante un asistente IA con lenguaje natural.

Producto de [JACAT Software](https://jacat.mx) · Repo: [github.com/julioamadortejeda/amconnect-app](https://github.com/julioamadortejeda/amconnect-app)

---

## Stack

| Capa | Tecnología |
|---|---|
| Framework | Flutter 3.x |
| Estado | Riverpod 3.x (`NotifierProvider`) |
| Navegación | GoRouter 17.x |
| Fuente | Space Grotesk (Google Fonts) |
| Backend (próximo) | Supabase Edge Functions (`amconnect-api`) |

---

## Estructura

```
lib/
├── core/
│   ├── mock/mock_data.dart          # Datos mock: clientes, pólizas, recordatorios, chat
│   ├── router/router.dart           # GoRouter: shell tabs + push routes con slide
│   ├── shell/shell_screen.dart      # Scaffold con bottom tab bar + FAB micrófono central
│   ├── theme/
│   │   ├── app_colors.dart          # Design tokens (AmColors) — single source of truth
│   │   └── theme.dart               # MaterialApp theme (AzulProTheme) basado en AmColors
│   └── widgets/                     # Componentes reutilizables
│       ├── am_avatar.dart           # Avatar con iniciales y color por cliente
│       ├── am_back_bar.dart         # AppBar premium con blur para pantallas push
│       ├── am_badge.dart            # Badges: accent / green / red / amber / muted
│       ├── am_card.dart             # Tarjeta blanca con sombra sutil
│       ├── am_icon_btn.dart         # Botón de ícono: soft / sunken / accent / ghost
│       ├── am_press.dart            # Wrapper de micro-interacción (scale 0.96)
│       ├── am_ramo_icon.dart        # Ícono coloreado por ramo: Auto/GMM/Vida/Hogar
│       ├── am_section_label.dart    # Etiqueta de sección en mayúsculas
│       └── am_segmented.dart        # Control segmentado estilo iOS
└── features/
    ├── onboarding/presentation/     # SplashScreen (anillos pulsantes) + LoginScreen
    ├── home/presentation/           # Dashboard: alertas, action cards, AI bar, cartera
    ├── clients/presentation/        # Lista con búsqueda + detalle con tabs pólizas/notas
    ├── reminders/presentation/      # Agenda con filtros + crear recordatorio
    ├── chat/presentation/           # Chat IA: typing dots, tarjetas estructuradas, bullets
    └── feed/presentation/           # Grid de tipos de carga + hoja de procesamiento
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

## Design tokens (AmColors)

Estilo **Privé** — superficies gris frío, tarjetas blancas, acento azul `#007AC0`.

```dart
AmColors.accent          // #007AC0 — azul principal
AmColors.bgLight         // #F5F6F7 — fondo scaffold
AmColors.cardLight       // #FFFFFF — fondo de tarjetas
AmColors.cardSunkenLight // #F2F3F5 — inputs, chips, fondos sunken
AmColors.inkLight        // #181D1B — texto principal
AmColors.inkSoftLight    // #4D544F — texto secundario
AmColors.mutedLight      // #8C9290 — texto terciario / labels
AmColors.lineLight       // #E5E6E8 — bordes y separadores
AmColors.accentWash      // #E8F3F9 — fondo sutil de elementos accent
AmColors.accentInk       // #006AA3 — texto sobre fondo accent wash
AmColors.greenLight      // #0E7C42 — positivo / al día
AmColors.redLight        // #D8453F — urgente / error
AmColors.amberLight      // #B9791A — advertencia / próximo
```

### Providers Riverpod

| Provider | Tipo | Archivo |
|---|---|---|
| `remindersProvider` | `NotifierProvider<RemindersNotifier, List<MockReminder>>` | `home_screen.dart` |
| `clientSearchProvider` | `NotifierProvider<_SearchNotifier, String>` | `clients_screen.dart` |

---

## Comandos

```bash
flutter pub get      # instalar dependencias
flutter analyze      # verificar errores
flutter run          # correr en simulador / dispositivo
flutter build ios    # build iOS
```

---

## Pendientes

- [ ] Conectar con backend Supabase (`amconnect-api` Edge Function)
- [ ] Autenticación real (Apple / Google Sign In)
- [ ] Reemplazar mock data con llamadas reales al Edge Function
- [ ] Modo oscuro (tokens dark listos en `AmColors`)
- [ ] Voz real en ChatScreen
- [ ] Subida real de archivos en FeedScreen
- [ ] Notificaciones push para recordatorios
