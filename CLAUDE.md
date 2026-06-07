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

### Cómo usar en cualquier pantalla o widget

```dart
import 'package:amconnect/l10n/app_localizations.dart';

@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return Text(l10n.algoClave);
}
```

- **Nunca** hardcodear strings visibles al usuario. Siempre `l10n.xxx`.
- Cada sub-widget con `BuildContext` propio (clases separadas) necesita su propio `AppLocalizations.of(context)!`.
- En callbacks con contexto diferente (e.g., `showModalBottomSheet builder: (ctx)`), usar `AppLocalizations.of(ctx)!`.

### Organización de claves ARB

Las claves siguen el prefijo del feature al que pertenecen:

| Prefijo | Feature |
|---|---|
| `login*` | Pantalla de login (social) |
| `emailLogin*` | Pantalla email/password |
| `register*` | Pantalla de registro |
| `shell*` | Bottom tab bar |
| `home*` | Dashboard |
| `clients*` | Lista y detalle de clientes |
| `reminders*` | Agenda y crear recordatorio |
| `chat*` | Pantalla de chat IA |
| `feed*` | Base de conocimiento |
| `field*` | Labels de campos de formulario |
| `err*` | Mensajes de error |
| `common*` | Strings reutilizables (cerrar, cuenta, etc.) |

### Strings con parámetros

```arb
"homeGreeting": "Hola, {name}",
"@homeGreeting": { "placeholders": { "name": { "type": "String" } } }
```

```dart
l10n.homeGreeting('Daniel')   // → "Hola, Daniel"
l10n.clientsTotal(5)          // → "5 en total"
```

### Agregar una nueva string

1. Agregar la clave en `lib/l10n/app_es.arb` (con `@key` si tiene parámetros).
2. Agregar la traducción en `lib/l10n/app_en.arb`.
3. Ejecutar `flutter gen-l10n` (o `flutter run` que lo hace automáticamente).
4. Usar `l10n.nuevaClave` en el widget.

### Agregar un nuevo idioma

Crear `lib/l10n/app_<locale>.arb` con las mismas claves que `app_es.arb` y agregar el locale a `supportedLocales` en `main.dart`.

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
│   │   ├── app_colors.dart         # Design tokens: AmColors — constantes light/dark + fijas
│   │   ├── am_theme.dart           # AmTheme ThemeExtension + extensión context.am
│   │   └── theme.dart              # AzulProTheme.lightTheme + AzulProTheme.darkTheme
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
| `remindersProvider` | `NotifierProvider<RemindersNotifier, List<MockReminder>>` | `home/providers/home_provider.dart` |
| `clientSearchProvider` | `NotifierProvider<_SearchNotifier, String>` | `clients_screen.dart` |

`RemindersNotifier` expone `.toggle(id)` para marcar hecho/pendiente. Es compartido entre HomeScreen y RemindersScreen — importar desde `home/providers/home_provider.dart`.

---

## Sistema de color adaptativo

La app tiene light y dark theme. **Nunca hardcodear `AmColors.xxxLight`** en widgets — usar siempre la capa más alta disponible:

### 1. `Theme.of(context).colorScheme` (la mayoría de colores)

```dart
final cs = Theme.of(context).colorScheme;
cs.onSurface          // texto principal (inkLight / inkDark)
cs.onSurfaceVariant   // texto secundario (inkSoftLight / inkSoftDark)
cs.tertiary           // texto muted (mutedLight / mutedDark)
cs.surface            // fondo de cards (cardLight / cardDark)
cs.secondaryContainer // fondo sunken (cardSunkenLight / cardSunkenDark)
cs.outline            // bordes (lineLight / lineDark)
cs.outlineVariant     // bordes sutiles
cs.error              // rojo (redLight / redDark)
cs.errorContainer     // fondo rojo suave
cs.primary            // azul principal #007AC0
cs.primaryContainer   // fondo badge accent
cs.onPrimaryContainer // texto sobre badge accent
```

### 2. `context.am` (colores no en ColorScheme: green, amber, muted2, bg, card2)

```dart
import 'package:amconnect/core/theme/am_theme.dart';

final am = context.am;
am.green / am.greenWash   // verde (llamadas, éxito)
am.amber / am.amberWash   // ámbar (pagos, alertas)
am.muted2                 // gris más suave
am.bg                     // fondo scaffold (rara vez — el theme lo aplica solo)
am.card2                  // superficie secundaria de cards
```

### 3. `AmColors.xxx` — solo constantes fijas (mismo valor en ambos temas)

```dart
AmColors.accent      // #007AC0 — ok para box shadows, FABs
AmColors.onAccent    // blanco sobre azul
AmColors.authBg      // solo pantallas de login
AmColors.srcDoc / srcWhatsApp / srcWave / srcImage / srcNote  // iconos de fuente
```

### Regla de Scaffold

**NO** poner `backgroundColor` en `Scaffold`. La `scaffoldBackgroundColor` está en el theme y se aplica automáticamente.

### Regla de const

`TextStyle`, `BoxDecoration`, etc. con colores del theme **no pueden ser `const`**. Quitar `const` del widget afectado.

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
- [x] Modo oscuro — `AzulProTheme.darkTheme` + `AmTheme` extension; todos los widgets usan `cs.*`/`context.am.*`
- [ ] Voz real en ChatScreen (actualmente solo texto)
- [ ] Subida real de archivos en FeedScreen
- [ ] Notificaciones push para recordatorios
- [x] i18n implementado — español + inglés via ARB + flutter_localizations

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

---

## Reglas del proyecto

- **No modificar versiones de dependencias.** Las versiones definidas en `pubspec.yaml` (Flutter, Riverpod, GoRouter, Google Fonts, etc.) **no deben cambiarse**. Si una API parece diferente a lo esperado, adaptarse al código existente — nunca actualizar o cambiar una versión para resolver la discrepancia.

- **Capa de repositorio obligatoria para acceso a datos externos.** Nunca acceder directamente a SDKs de infraestructura (Supabase, Firebase, APIs REST, etc.) desde un `Notifier` o una pantalla. Todo acceso a datos externos debe pasar por un `Repository`:

```
core/
└── repositories/
    ├── auth_repository.dart          # Interfaz abstracta
    └── supabase_auth_repository.dart # Implementación concreta + Provider
```

**Flujo correcto:**
```
Pantalla → ref.watch/read(provider) → Notifier → ref.read(repositoryProvider) → Repository → SDK
```

**Ejemplo de estructura:**
```dart
// 1. Interfaz abstracta (lib/core/repositories/foo_repository.dart)
abstract class FooRepository {
  Future<void> doSomething();
}

// 2. Implementación concreta (lib/core/repositories/supabase_foo_repository.dart)
class SupabaseFooRepository implements FooRepository {
  final SupabaseClient _client;
  SupabaseFooRepository(this._client);

  @override
  Future<void> doSomething() async {
    await _client.from('foo').select();
  }
}

final fooRepositoryProvider = Provider<FooRepository>((ref) {
  return SupabaseFooRepository(Supabase.instance.client);
});

// 3. Notifier (features/foo/providers/foo_provider.dart)
class FooNotifier extends Notifier<FooState> {
  late final FooRepository _repo;

  @override
  FooState build() {
    _repo = ref.read(fooRepositoryProvider);
    return FooState();
  }

  Future<void> load() => _repo.doSomething();
}
```
