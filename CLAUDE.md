# AMConnect Flutter App — CLAUDE.md

> **Obligatorio:** lee `RULES.md` (mismo directorio) antes de escribir código. Ahí están las reglas duras de i18n, theming, widgets, Riverpod, errores y rendimiento.

Contexto general del proyecto: `/Users/Development/Projects/JACATSoft/context.md` · Backlog: `/Users/Development/Projects/JACATSoft/backlog.md`

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
│   ├── shell/shell_screen.dart   # Bottom tab bar + FAB del asistente (logo → /chat)
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
    ├── feed/                 # ingesta de documentos
    └── share_target/         # contenido compartido desde otras apps
```

---

## Rutas (GoRouter)

> Tabla actualizada 2026-08-04 contra `lib/core/router/router.dart` (la tabla previa estaba desactualizada: decía `/clients` en vez de `/portfolio` y omitía varias rutas).

| Path | Pantalla | Tipo |
|---|---|---|
| `/` | SplashScreen | full (fade) |
| `/login` | LoginScreen | full (fade) |
| `/email-login` | EmailLoginScreen | push |
| `/register` | RegisterScreen | push |
| `/forgot-password` | ForgotPasswordScreen | push |
| `/home` | HomeScreen | shell tab |
| `/reminders` | RemindersScreen | shell tab |
| `/portfolio` | ClientsScreen | shell tab |
| `/data` | FeedScreen | shell tab |
| `/analytics` | AnalyticsScreen | push |
| `/create-client` | CreateClientScreen | push |
| `/create-policy` | CreatePolicyScreen | push |
| `/policy/:id` | PolicyDetailScreen | push |
| `/clients/:id` | ClientDetailScreen | push |
| `/create-reminder` | CreateReminderScreen | push |
| `/reminder/:id` | ReminderDetailScreen | push |
| `/chat` | **AssistantScreen** — única feature de chat de la app | push |
| `/account` | AccountScreen | push |
| `/catalogs` | CatalogsScreen | push |
| `/share-target` | ShareTargetScreen | push |

**Nota (2026-08-04) — consolidación de chat:** hasta julio 2026 coexistían tres features de chat (`features/chat/`, `features/assistant/`, `features/chat_tts/`) con rutas `/chat`, `/voice-chat` y `/voice-chat-tts`. Las dos últimas eran código muerto (sin navegación real) y se eliminaron junto con sus pantallas/providers/widgets. `features/assistant/` (ruta `/chat`, `AssistantScreen`) es ahora la **única** feature de chat — sirve texto y voz, con o sin `AiChatContext` (contexto opcional de pantalla). Los activos compartidos que vivían dentro de `chat/` se movieron a `core/`: `AiChatContext` → `core/models/ai_chat_context.dart`, `buildChatCard` → `core/widgets/chat_cards.dart`.

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

Tablas habilitadas: `contacts`, `policies`, `reminders`, `agent_notes`, `client_commitments`, `reminder_comments` (todas con `REPLICA IDENTITY FULL` + publicación supabase_realtime).

**Tabla hija cuyos datos viajan dentro del padre** (caso `reminder_comments`): la fila del padre NO cambia al insertar un hijo, así que su canal no dispara. Hace falta un canal propio para la tabla hija —nunca mezclado en el del padre— cuyo callback re-consulte el padre por id y lo reemplace en la lista. Sin eso, la pantalla no se entera: el asesor le dicta una nota a la IA, no ve nada, la vuelve a dictar y quedan dos (2026-09-04). Para datos por pantalla (detalle) usar el patrón dos providers: `FutureProvider.family` (datos) + `Provider.autoDispose.family<void>` que llama `ref.invalidate` — `autoDispose` cierra el canal al salir de la pantalla.

Para listas principales, el patrón en cada `AsyncNotifier`: El patrón en cada `AsyncNotifier`:

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

## Formatters (`core/utils/formatters.dart`)

Funciones globales de formato. **Nunca usar `NumberFormat` o `DateFormat` directamente en widgets** — siempre usar estas funciones para consistencia visual.

```dart
import 'package:amconnect/core/utils/formatters.dart';
```

| Función | Input | Output | Uso |
|---|---|---|---|
| `fmtCurrency(v)` | `double?` | `"$150,000"` | Suma asegurada, primas, montos |
| `fmtPremium(v, freq)` | `double?, String` | `"$3,615 · Annual"` | Prima con frecuencia |
| `fmtDate(dt)` | `DateTime?` | `"13 jun 2026"` | Fechas de pólizas y general |
| `fmtDate(dt, showYear: false)` | `DateTime?` | `"13 jun"` | Fechas compactas en listas |
| `fmtDateFromIso(iso)` | `String?` | `"13 jun 2026"` | Fechas ISO del API |
| `fmtSmartDate(dt, l10n)` | `DateTime?, l10n` | `"Hoy"` / `"Mañana"` / `"13 jun"` | Recordatorios en listas |
| `fmtDateWithWeekday(dt)` | `DateTime?` | `"lun 13 jun 2026"` | Timestamps de comentarios/detalle |
| `fmtTime(dt)` | `DateTime?` | `"10:30"` / `"—"` | Hora de recordatorios |
| `fmtTime(dt, fallback: '')` | `DateTime?` | `"10:30"` / `""` | Hora cuando vacío no muestra nada |

**Reglas:**
- `fmtSmartDate` requiere `AppLocalizations` — solo usar en widgets con `BuildContext`
- "Hoy" y "Mañana" **solo** via `fmtSmartDate` con `l10n` — nunca hardcodear esos strings

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

## VoiceOverlay — parámetros clave

- `continueSession: bool` — si `false` → reset de sesión al abrir.
- `navigateToChat: bool` — si `false` → el overlay envía el mensaje pero NO navega a /chat (úsalo cuando ya estás en la pantalla de chat).
- `initialContext: AiChatContext?` — si presente → `resetWithContext`.
- El caller decide la navegación, no el overlay.

## Composer del asistente — dictado vs. voz Live

Dos formas distintas de hablarle, y NO son lo mismo:

- **Dictado** (`core/services/speech_dictation_service.dart`): STT del sistema, on-device. El audio no sale del teléfono; solo el texto viaja después por `POST /ai/chat`. No cuesta tokens.
- **Voz Live** (`core/services/gemini_voice_engine.dart`): WebSocket full-duplex con Gemini. Cobra el audio a ~25 tokens/seg y recobra el contexto en cada turno.

Los dos se pelean el micrófono — **nunca activos a la vez**. El candado vive en `AssistantNotifier` (`startDictation` se rehúsa en modo voz; `startVoice` cancela el dictado), no en la UI.

A la derecha del composer hay SIEMPRE dos botones, nunca cuatro:

| Estado | izq | centro | gris | azul |
|---|---|---|---|---|
| Vacío | clip | campo | mic | onda (Live) |
| Con texto | clip | campo | mic | enviar |
| Dictando | clip | ondas | stop | enviar |

- `stop` termina el dictado y deja el texto en el campo; el botón azul lo termina **y envía**.
- Terminar por silencio (3 s) nunca envía solo — el STT falla con nombres propios y el asesor tiene que poder corregir.
- El texto parcial no se pinta: parpadea y se corrige solo. La onda ya comunica que está oyendo.
- Android necesita el `<queries>` de `android.speech.RecognitionService` en el manifest; sin él `initialize()` devuelve false en Android 11+.

## Animaciones de entrada — `AmAnimateIn` vs `AmStagger`

`AmStagger` es una `Column` (sin scroll) — solo para listas cortas estáticas. Para contenido dentro de `ListView`, usar `AmAnimateIn(index: N, child: ...)` en cada sección. Nunca poner `AmStagger` dentro de un `ListView`.

## Manejo de errores en UI

- Los repositorios lanzan `ApiException` (`statusCode`, `message`, `errorCode`).
- Mostrar errores SOLO con `context.translateError(...)` (`core/utils/error_translator.dart`): código conocido → string localizada; desconocido → mensaje del backend tal cual.
- Código nuevo del backend ⇒ agregar case en `error_translator.dart` + claves `err*` en ambos ARB.

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
- [x] Voz real en VoiceOverlay (integrada con Gemini 3.1 Live API por WebSocket con audio PCM bidireccional y transcripciones visibles)
- [x] Share target — recibir archivos/texto compartidos desde otras apps y asignarlos a alta de póliza, cliente, póliza, recordatorio o base de conocimiento

## Share target (contenido compartido desde otras apps)

`ShareHandlerListener` (montado en `ShellScreen`) escucha `flutter_sharing_intent` y hace push de `/share-target`. En esa pantalla se elige el destino y `ShareTargetNotifier.dispatch()` delega en `ingestProvider` — el mismo pipeline del Feed, así que `IngestFlowOverlay` muestra progreso, confirmación y errores.

- **Alta de póliza** (`processPolicy`): solo PDF/imagen. Flujo automático — detección de cliente, catálogos y recordatorios.
- **Cliente / Póliza / Recordatorio / Global**: `processKnowledgeFile` o `processKnowledgeText` → nota (`agent_notes`) ligada SOLO al destino elegido (`contactId`, `policyId` o `reminderId`); global no lleva ninguno.
- **iOS**: la Share Extension (`ios/ShareExtension/`) debe redirigir a `SharingMedia-<bundle id>://dataUrl=SharingKey` — el plugin ignora cualquier otro scheme — y guardar el payload en el App Group con el shape exacto de su modelo `SharingFile` (`type` es el enum `text,url,image,video,file`). Las rutas van con prefijo `file://`.
- Cerrar `/share-target` ANTES de despachar la ingesta: los sheets del overlay usan el mismo navigator que GoRouter.

## Gemini Live API & Token Tracking Rules

*   **Audio Token Conversion Rates**: Input/Output audio is converted to native tokens. Audio files and streams translate to approximately **32 tokens per second** (or **25 tokens per second** in active Live API WebSocket sessions).
*   **Compounding Billing Model**: Gemini Live API operates on a WebSocket connection. Because of this, it bills per **turn** for **all tokens currently inside the active session context window**. This means that previous turns (both input and output audio) are re-processed and re-billed on every single new turn.
*   **Transcription Surcharges**: When audio transcription is enabled (`inputAudioTranscription` or `outputAudioTranscription`), generated text tokens are billed at standard output text rates **in addition** to the native audio token costs.
*   **Usage Metadata Timing & Delay**: In WebSocket streams, the final `usageMetadata` packet (containing final `completion_tokens` and total token count) can arrive in a separate, final server packet **after** the `turnComplete` event. To prevent loss of token counts, client applications must not immediately write or reset counters on `turnComplete`; a small delay (e.g. 400ms) or buffering should be used.

### Pendiente
- [ ] Acciones rápidas de cliente (llamar, mensaje — placeholders)
- [ ] Pantalla de pólizas por cliente (tabs vacíos en ClientDetail)
- [ ] Notificaciones push para recordatorios

---

## Cambios Recientes

- **Chat de Texto y Voz:** El chat de texto y los ajustes del chat de voz (con las correcciones del nuevo formato de audio `realtimeInput.audio` para evitar la desconexión del WebSocket en Gemini 3.1 Live API) están listos y validados.
- **Optimización y Estabilización de UI en Voz:** Se optimizó `AmAurora` para suspender el pintado durante las transiciones de ruta (eliminando el lag al entrar/salir de la pantalla) y se fijó la altura de la barra inferior a 76px (junto con una onda de voz de 28px de altura máxima) para evitar desplazamientos verticales del orbe del micrófono al cambiar de estado (detalles en [walkthrough.md](file:///Users/julio/.gemini/antigravity/brain/a411ae05-c358-412b-93b2-578d9f685c96/walkthrough.md)).


