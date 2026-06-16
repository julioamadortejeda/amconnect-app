# AMConnect Flutter App — CLAUDE.md

## Contexto del proyecto

App móvil Flutter para asesores de seguros. Permite gestionar clientes, pólizas, recordatorios y chatear con un asistente IA. Diseño basado en prototipo HTML/CSS exportado desde Claude Design.

**Stack:** Flutter · Riverpod 3.x · GoRouter · Google Fonts · flutter_localizations (i18n)

---

## Internacionalización (i18n)

La app usa **Flutter ARB + flutter_localizations** (SDK oficial, sin dependencias externas).

### Archivos clave

```
lib/l10n/
├── app_es.arb              # Español — plantilla maestra (template)
├── app_en.arb              # Inglés
├── app_localizations.dart  # Generado por flutter gen-l10n — NO editar a mano
├── app_localizations_es.dart
└── app_localizations_en.dart
l10n.yaml                   # arb-dir, template, output file
```

### Cómo usar

```dart
import 'package:amconnect/l10n/app_localizations.dart';

final l10n = AppLocalizations.of(context)!;
Text(l10n.algoClave)
```

- **Nunca** hardcodear strings visibles al usuario. Siempre `l10n.xxx`.
- Cada sub-widget con `BuildContext` propio necesita su propio `AppLocalizations.of(context)!`.
- En callbacks con contexto diferente (`showModalBottomSheet builder: (ctx)`), usar `AppLocalizations.of(ctx)!`.

### Organización de claves ARB

| Prefijo | Feature |
|---|---|
| `login*` | Login social |
| `emailLogin*` | Login email/password |
| `register*` | Registro |
| `shell*` | Bottom tab bar |
| `home*` | Dashboard |
| `clients*` | Lista y detalle de clientes |
| `reminders*` / `reminder*` / `calendar*` | Agenda y detalle de recordatorio |
| `chat*` | Chat IA |
| `feed*` | Base de conocimiento |
| `field*` | Labels de campos de formulario |
| `err*` | Mensajes de error |
| `common*` | Strings reutilizables |

### Agregar una nueva string

1. Agregar en `lib/l10n/app_es.arb` (con `@key` si tiene parámetros).
2. Agregar traducción en `lib/l10n/app_en.arb`.
3. Ejecutar `flutter gen-l10n`.
4. Usar `l10n.nuevaClave` en el widget.

---

## Estructura del proyecto

```
lib/
├── core/
│   ├── models/               # Contact, Reminder, ReminderType, Policy…
│   ├── repositories/         # Interfaces abstractas + implementaciones Supabase
│   ├── network/              # ApiClient (HTTP al Edge Function)
│   ├── router/router.dart    # GoRouter
│   ├── shell/shell_screen.dart   # Bottom tab bar + FAB micrófono
│   ├── theme/
│   │   ├── app_colors.dart   # AmColors — tokens fijos
│   │   ├── am_theme.dart     # AmTheme ThemeExtension + context.am
│   │   └── theme.dart        # AzulProTheme.lightTheme/darkTheme
│   ├── utils/                # reminder_utils.dart, catalog_l10n.dart…
│   └── widgets/              # (ver tabla de widgets reutilizables abajo)
└── features/
    ├── onboarding/           # splash, login, email_login, register
    ├── home/                 # dashboard + providers + widgets
    ├── clients/              # lista, detalle, provider, widgets
    ├── reminders/            # agenda, detalle, crear, provider, widgets
    ├── chat/                 # chat IA, voice overlay, widgets
    └── feed/                 # ingesta de documentos
```

---

## Rutas (GoRouter)

| Path | Pantalla | Tipo |
|---|---|---|
| `/` | SplashScreen | full |
| `/login` | LoginScreen | full |
| `/email-login` | EmailLoginScreen | full |
| `/register` | RegisterScreen | full |
| `/home` | HomeScreen | shell tab |
| `/reminders` | RemindersScreen | shell tab |
| `/clients` | ClientsScreen | shell tab |
| `/data` | FeedScreen | shell tab |
| `/clients/:id` | ClientDetailScreen | push slide |
| `/create-reminder` | CreateReminderScreen | push slide |
| `/reminder/:id` | ReminderDetailScreen | push slide |
| `/chat` | ChatScreen | push slide |

---

## Widgets reutilizables (`core/widgets/`)

| Widget | Props clave | Notas |
|---|---|---|
| `AmPress` | `onTap`, `scale` | Animación 0.96 al presionar |
| `AmCard` | `onTap`, `noPad`, `padding` | Shadow + radius `AmDimens.cardRadius` |
| `AmBadge` | `label`, `tone` (accent/green/red/amber/muted), `icon` | |
| `AmAvatar` | `inicial`, `color`, `size`, `radius` | Iniciales + color derivado del id |
| `AmIconBtn` | `icon`, `tone`, `dim`, `dot` | Tones: soft/sunken/accent/ghost/onPrimary |
| `AmSegmented` | `options`, `selected`, `onSelect` | Tabs estilo iOS |
| `AmSectionLabel` | `label`, `trailing` | Label en uppercase |
| `AmTopBar` | `title`, `subtitle`, `actions`, `showBack`, `onBack` | AppBar estándar — usar en toda pantalla nueva |
| `AmBackBar` | `title`, `trailing`, `onBack` | Blur+glass — legacy, no usar en nuevas pantallas |
| `AmLoader` | — | Indicador de carga estándar (reemplaza CircularProgressIndicator) |
| `AmCalendar` | `visibleMonth`, `selectedDate`, `events`, callbacks | Calendario mensual con dots de eventos |
| `AmAurora` | `delay` | Fondo animado para VoiceOverlay |
| `AmRamoIcon` | `ramo`, `size` | Icono coloreado por tipo de póliza |
| `AmConfirmDialog` | `title`, `message`, `onConfirm` | Diálogo de confirmación animado |
| `AmCancelDialog` | `reminder`, `onConfirm` | Diálogo de cancelación con motivo |
| `AmRescheduleDialog` | `initialDateTime`, `onConfirm` | Picker fecha/hora |
| `AmFadeAnimation` | `child`, `delay` | Fade + slide in de entrada |
| `AmTextField` | — | Campo de texto estilizado para formularios |

---

## Arquitectura de features

### Separación pantalla / lógica

- Las **pantallas** solo hacen `ref.watch` / `ref.read` + renderizan.
- Toda lógica va en el **provider** de la feature (`features/<nombre>/providers/<nombre>_provider.dart`).
- No hay funciones async inline en `build`, ni acceso directo a SDKs desde pantallas.

### Widgets — un archivo por widget, sin clases privadas en pantallas

- **Nunca** clases privadas con `_` en un archivo de pantalla (`presentation/`).
- Clases auxiliares privadas (`_Action`, `_Row`…) son aceptables dentro de archivos de **widget** (no de pantalla) como detalle de implementación.
- Widget reutilizable entre features → `core/widgets/am_<nombre>.dart`
- Widget específico de un feature → `features/<feature>/widgets/<nombre>.dart`

### Estructura de un feature completo

```
features/<nombre>/
├── presentation/
│   └── <nombre>_screen.dart       # solo UI
├── providers/
│   └── <nombre>_provider.dart     # Notifier + providers derivados + UI state
└── widgets/
    └── <widget_name>.dart         # un archivo por widget
```

### Providers UI en el archivo de provider

Los `Notifier` de estado de UI (filtros, selección de tab, búsqueda…) van en el archivo `<feature>_provider.dart`, no en el archivo de pantalla. Ejemplo: `clientSearchProvider` está en `clients_provider.dart`.

---

## Estado con Riverpod 3.x

**Riverpod 3.x eliminó `StateProvider`.** Usar siempre `Notifier` + `NotifierProvider`.

```dart
class MyNotifier extends Notifier<MyState> {
  @override
  MyState build() => MyState();
  void update(MyState s) => state = s;
}
final myProvider = NotifierProvider<MyNotifier, MyState>(MyNotifier.new);
```

### Providers existentes

| Provider | Tipo | Dónde |
|---|---|---|
| `remindersProvider` | `AsyncNotifierProvider<RemindersNotifier, List<Reminder>>` | `home/providers/home_provider.dart` |
| `remindersUiProvider` | `NotifierProvider<RemindersNotifier, RemindersState>` | `reminders/providers/reminders_provider.dart` |
| `filteredRemindersProvider` | `Provider<List<Reminder>>` | `reminders/providers/reminders_provider.dart` |
| `selectedDayRemindersProvider` | `Provider<List<Reminder>>` | `reminders/providers/reminders_provider.dart` |
| `remindersByDateProvider` | `Provider<Map<DateTime,List<Reminder>>>` | `reminders/providers/reminders_provider.dart` |
| `reminderTypesProvider` | `FutureProvider<List<ReminderType>>` | `reminders/providers/reminders_provider.dart` |
| `agentNameProvider` | `FutureProvider<String>` | `home/providers/home_provider.dart` |
| `policiesCountProvider` | `AsyncNotifierProvider<PoliciesCountNotifier, int>` | `home/providers/home_provider.dart` |
| `homeReadyProvider` | `FutureProvider<bool>` | `home/providers/home_provider.dart` |
| `homeDashboardProvider` | `Provider<HomeDashboardData>` | `home/providers/home_provider.dart` |
| `clientsProvider` | `AsyncNotifierProvider<ClientsNotifier, List<Contact>>` | `clients/providers/clients_provider.dart` |
| `clientSearchProvider` | `NotifierProvider<_SearchNotifier, String>` | `clients/providers/clients_provider.dart` |
| `contactDetailProvider` | `FutureProvider.family<Contact, String>` | `clients/providers/clients_provider.dart` |

### Realtime (Supabase)

`reminders`, `contacts` y `policies` tienen suscripciones Realtime activas. El patrón en cada `AsyncNotifier`:

```dart
RealtimeChannel? _channel;

@override
Future<List<T>> build() async {
  _repo = ref.read(repositoryProvider);
  final initial = await _repo.getAll();
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId != null) {
    _channel = Supabase.instance.client
        .channel('tabla:$userId')
        .onPostgresChanges(/* INSERT/UPDATE/DELETE */)
        .subscribe();
    ref.onDispose(() { _channel?.unsubscribe(); });
  }
  return initial;
}
```

- **INSERT**: guardar en lista solo si no existe ya (guard de echo optimista).
- **UPDATE con `is_active == false`**: tratar como soft-delete → remover de lista.
- **UPDATE normal**: refetch por id via `_repo.getById(id)` y reemplazar en lista.
- **DELETE**: remover por id.

### `ref` en closures async

Capturar el notifier **antes** de cualquier `Navigator.pop` o `await`, para evitar uso de `ref` después de que el widget sea disposed:

```dart
// ✅ Correcto
final notifier = ref.read(remindersProvider.notifier);
Navigator.pop(context);
notifier.updateStatus(id, 'DONE');

// ❌ Incorrecto — ref puede estar disposed
Navigator.pop(context);
ref.read(remindersProvider.notifier).updateStatus(id, 'DONE');
```

---

## Patrón de pantalla estándar

### Con AppBar (`AmTopBar`)

```dart
return Scaffold(
  appBar: AmTopBar(
    title: l10n.myTitle,
    subtitle: l10n.mySubtitle,         // opcional
    showBack: true,                     // para pantallas push
    actions: [ /* botones */ SizedBox(width: AmDimens.screenH) ],
  ),
  body: SafeArea(
    top: false,                         // AmTopBar ya cubre el status bar
    child: /* contenido */,
  ),
);
```

- Usar `AmTopBar` para todas las pantallas nuevas. `AmBackBar` es legacy.
- El último elemento de `actions` siempre es `SizedBox(width: AmDimens.screenH)` para el margen derecho.
- `body` siempre con `SafeArea(top: false)`.

### Pantalla de detalle

```dart
body: SafeArea(
  top: false,
  child: ListView(
    padding: const EdgeInsets.fromLTRB(
        AmDimens.screenH, AmDimens.gapM, AmDimens.screenH, 40),
    children: [
      HeroWidget(...),
      const SizedBox(height: AmDimens.gapM),
      AmSectionLabel(label: l10n.section),
      const SizedBox(height: AmDimens.gapXS),
      ContentWidget(...),
    ],
  ),
),
```

### Estados de carga/error

Usar `AmLoader()` en lugar de `CircularProgressIndicator`. En `AsyncValue.when`:

```dart
loading: () => const AmLoader(),
error: (_, __) => Center(child: Text(l10n.myError, style: TextStyle(color: cs.tertiary))),
```

---

## Sistema de color adaptativo

La app tiene light y dark theme. **Nunca hardcodear colores fijos** en widgets — usar:

### 1. `Theme.of(context).colorScheme`

```dart
final cs = Theme.of(context).colorScheme;
cs.onSurface          // texto principal
cs.onSurfaceVariant   // texto secundario
cs.tertiary           // texto muted / labels
cs.surface            // fondo de cards
cs.secondaryContainer // fondo sunken (chips, iconos inactivos)
cs.outlineVariant     // bordes sutiles (divisores)
cs.outline            // bordes normales
cs.error / cs.errorContainer
cs.primary            // azul #007AC0
cs.primaryContainer / cs.onPrimaryContainer
cs.onPrimary          // blanco sobre primario
```

### 2. `context.am` (colores fuera del ColorScheme)

```dart
import 'package:amconnect/core/theme/am_theme.dart';
final am = context.am;
am.green / am.greenWash   // éxito, al día
am.amber / am.amberWash   // advertencia, pagos
am.muted2 / am.bg / am.card2
```

### 3. `AmColors.xxx` — solo constantes absolutas

```dart
AmColors.accent      // #007AC0 — shadows de FABs y botones primarios
AmColors.onAccent    // blanco sobre azul
AmColors.authBg      // solo pantallas de login
```

### Reglas

- **No** poner `backgroundColor` en `Scaffold` (lo aplica el theme).
- `TextStyle`, `BoxDecoration` con colores del theme **no pueden ser `const`**.
- Colores sobre fondo primario (`cs.primary`): usar `Colors.white` y `Colors.white.withValues(alpha: x)`. `AmIconBtn` tiene el tone `onPrimary` para este caso.

---

## Dimensiones y espaciados (`AmDimens`)

Definidos en `lib/core/theme/app_dimensions.dart`. **Nunca valores numéricos crudos.**

| Token | Valor | Uso |
|---|---|---|
| `screenH` | 18.0 | Padding horizontal de pantallas |
| `cardPad` | 18.0 | Padding interno de `AmCard` |
| `cardRadius` | 18.0 | Radio de cards, diálogos, contenedores |
| `gapL` | 20.0 | Separación entre secciones principales |
| `gapM` | 16.0 | Separación entre ítems de sección |
| `gapS` | 14.0 | Separación entre filas de lista |
| `gapXS` | 11.0 | Entre label de sección y su contenido |
| `scrollBottomPad` | 100.0 | Padding inferior en listas (espacio para tab bar + FAB) |

---

## Widgets con animaciones — tamaño fijo

Los widgets que animan su tamaño internamente (expansión de rings, etc.) **deben declarar un `SizedBox` de tamaño fijo** antes del `Stack`/contenedor animado, para que el layout externo no se mueva:

```dart
// ✅ Correcto — el Column exterior no se mueve
return SizedBox(
  width: 140, height: 140,
  child: Stack(alignment: Alignment.center, children: [...]),
);

// ❌ Incorrecto — el Stack crece/encoge y empuja los widgets adyacentes
return Stack(alignment: Alignment.center, children: [...]);
```

---

## Soft-delete y visibilidad

Todos los deletes usan `is_active = false` + `deleted_at` (nunca `DELETE`). En la UI:

- **Lista activa**: filtrar con `r.isActive` (excluye done + cancelled).
- **Vista cancelados**: filtrar con `r.cancelled` (sin `IgnorePointer`; usar `showContextMenu: false` en `ReminderItem` para deshabilitar el long-press sin bloquear el tap de detalle).
- **Detalle de cancelado**: solo lectura — no mostrar botones de edición, ni activar `onTap` en tipo/status/reagendar.
- **Vista calendario**: `selectedDayRemindersProvider` y `remindersByDateProvider` filtran por `r.isActive`.

---

## Diálogos y bottom sheets

- Diálogos comunes en `core/widgets/`: `AmConfirmDialog`, `AmCancelDialog`, `AmRescheduleDialog`.
- Animaciones con `Curves.easeOutBack` u otras que excedan [0,1]: limitar opacity con `.clamp(0.0, 1.0)`.
- `showModalBottomSheet`: siempre `useRootNavigator: true`, `backgroundColor: cs.surface`, `shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)))`.

---

## Capa de repositorio

**Nunca** acceder directamente a SDKs desde `Notifier` o pantallas. Flujo obligatorio:

```
Pantalla → ref.watch/read(provider) → Notifier → ref.read(repositoryProvider) → Repository → ApiClient/SDK
```

Repositorios en `core/repositories/`:
- `contact_repository.dart` + `supabase_contact_repository.dart`
- `reminder_repository.dart` + `supabase_reminder_repository.dart`
- `policy_repository.dart` + `supabase_policy_repository.dart`
- `agent_repository.dart` + `supabase_agent_repository.dart`
- `auth_repository.dart` + `supabase_auth_repository.dart`

---

## Comandos útiles

```bash
# Desde amconnect-app/amconnect/
flutter analyze          # verificar errores (debe salir con 0 errores/warnings)
flutter gen-l10n         # regenerar localizaciones tras editar ARB
flutter run              # correr en simulador/dispositivo
flutter build ios        # build iOS
```

## Assets disponibles

```
assets/logo/
├── logo.png     # logo con fondo
└── logo_t.png   # logo transparente (usado en la app)
```

---

## Estado actual de la app

### Conectado al backend (real)
- [x] Autenticación con Supabase (email/password, Google)
- [x] Recordatorios — CRUD completo + Realtime
- [x] Contactos — CRUD completo + Realtime
- [x] Pólizas — conteo + Realtime
- [x] Dashboard — datos reales (agente, stats, reminders)
- [x] Chat IA — integrado con Edge Function `amconnect-api`
- [x] Ingesta de documentos (Feed)

### Pendiente
- [ ] Voz real en VoiceOverlay (actualmente sin STT)
- [ ] Acciones rápidas de cliente (llamar, mensaje — placeholders)
- [ ] Pantalla de pólizas por cliente (tabs vacíos en ClientDetail)
- [ ] Notificaciones push para recordatorios
