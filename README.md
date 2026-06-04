# AMConnect — App móvil

App móvil para asesores de seguros. Permite gestionar clientes, pólizas y recordatorios, y consultar información mediante un asistente IA con lenguaje natural.

Producto de [JACAT Software](https://jacat.mx).

---

## Stack

| Capa | Tecnología |
|---|---|
| Framework | Flutter 3.x |
| Estado | Riverpod 3.x (`NotifierProvider`) |
| Navegación | GoRouter 17.x |
| Fuente | Space Grotesk (Google Fonts) |
| Backend | Supabase Edge Functions (`amconnect-api`) |

---

## Estructura

```
lib/
├── core/
│   ├── mock/mock_data.dart          # Datos de prueba (clientes, pólizas, recordatorios, chat)
│   ├── router/router.dart           # GoRouter: shell tabs + push routes
│   ├── shell/shell_screen.dart      # Scaffold con bottom tab bar + FAB micrófono
│   ├── theme/
│   │   ├── app_colors.dart          # Design tokens (AmColors)
│   │   └── theme.dart               # MaterialApp theme (AzulProTheme)
│   └── widgets/                     # Componentes reutilizables
│       ├── am_avatar.dart
│       ├── am_back_bar.dart
│       ├── am_badge.dart
│       ├── am_card.dart
│       ├── am_icon_btn.dart
│       ├── am_press.dart
│       ├── am_ramo_icon.dart
│       ├── am_section_label.dart
│       └── am_segmented.dart
└── features/
    ├── onboarding/presentation/     # SplashScreen + LoginScreen
    ├── home/presentation/           # Dashboard del asesor
    ├── clients/presentation/        # Lista de clientes + detalle
    ├── reminders/presentation/      # Agenda + crear recordatorio
    ├── chat/presentation/           # Chat con asistente IA
    └── feed/presentation/           # Subir documentos / datos
```

---

## Rutas

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

```dart
AmColors.accent         // #007AC0 — azul principal
AmColors.bgLight        // #F5F6F7 — fondo scaffold (gris frío)
AmColors.cardLight      // #FFFFFF — fondo de tarjetas
AmColors.cardSunkenLight // #F2F3F5 — fondo sunken (inputs, chips)
AmColors.inkLight       // #181D1B — texto principal
AmColors.inkSoftLight   // #4D544F — texto secundario
AmColors.mutedLight     // #8C9290 — texto terciario
AmColors.lineLight      // #E5E6E8 — bordes / separadores
AmColors.accentWash     // #E8F3F9 — fondo sutil de elementos accent
AmColors.accentInk      // #006AA3 — texto sobre fondo accent wash
AmColors.greenLight     // #0E7C42 — estado positivo
AmColors.redLight       // #D8453F — estado urgente / error
AmColors.amberLight     // #B9791A — estado de advertencia
```

---

## Comandos

```bash
# Instalar dependencias
flutter pub get

# Analizar código
flutter analyze

# Correr en simulador / dispositivo
flutter run

# Build iOS
flutter build ios
```

---

## Pendientes

- [ ] Conectar con backend Supabase (`amconnect-api`)
- [ ] Autenticación real (Apple / Google Sign In)
- [ ] Reemplazar mock data con llamadas reales al Edge Function
- [ ] Modo oscuro (tokens dark listos en `AmColors`)
- [ ] Voz real en ChatScreen
- [ ] Subida real de archivos en FeedScreen
- [ ] Notificaciones push para recordatorios
