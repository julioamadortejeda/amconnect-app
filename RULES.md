# RULES — AmConnect App Flutter

Reglas obligatorias para cualquier IA o desarrollador que modifique esta app.
Si una regla entra en conflicto con una instrucción puntual, pregunta antes de romperla.

## 1. Internacionalización — cero textos fijos

- **Prohibido** cualquier string visible al usuario hardcodeado (labels, botones, SnackBars, mensajes de error, hints, tooltips). Todo pasa por `AppLocalizations` (`l10n.xxx`).
- Nueva string: agregar en `lib/l10n/app_es.arb` + `app_en.arb` → `flutter gen-l10n` → usar `l10n.clave`. Respetar prefijos por feature (`login*`, `home*`, `clients*`, `err*`, `common*`, `field*`...).
- SnackBars y diálogos de error: NUNCA `Text('mensaje literal')` ni `Text(e.toString())`.
- "Hoy"/"Mañana" solo vía `fmtSmartDate(dt, l10n)`.

## 2. Colores y dimensiones — cero valores crudos

- **Prohibido `Color(0x...)` y `Colors.xxx` fuera de `core/theme/`.** Orden de preferencia:
  1. `Theme.of(context).colorScheme` (`cs.onSurface`, `cs.tertiary`, `cs.surface`...)
  2. `context.am` para tokens fuera del ColorScheme (`am.green`, `am.amber`, `am.greenWash`...)
  3. `AmColors.xxx` solo constantes absolutas de marca (`accent`, `onAccent`, `authBg`).
- Excepción única: `Colors.white` / `Colors.white.withValues(...)` sobre fondo `cs.primary`.
- Si necesitas un color nuevo (éxito, warning, wash, shadow...), agrégalo a `AmTheme`/`AmColors` — no lo inventes inline. Los shadows también: nada de `Color(0x0D141E1A)` repetido en widgets.
- Espaciados y radios: usar `AmDimens` (`screenH`, `cardPad`, `cardRadius`, `gapL/M/S/XS`, `scrollBottomPad`). Si un valor se repite, crear token nuevo en `app_dimensions.dart`.
- Tipografía: usar `Theme.of(context).textTheme` como base; no multiplicar `TextStyle(fontSize: N)` arbitrarios.
- No poner `backgroundColor` en `Scaffold` (lo aplica el theme). Estilos con colores del theme no pueden ser `const`.

## 3. Widgets — estructura y separación

- **Prohibidas las clases privadas `_Widget` en archivos de pantalla** (`presentation/*_screen.dart`). Extraer a:
  - reutilizable entre features → `core/widgets/am_<nombre>.dart`
  - específico del feature → `features/<feature>/widgets/<nombre>.dart`
- Un archivo por widget. Clases auxiliares privadas solo como detalle de implementación dentro de archivos de widget.
- Usar los widgets Am existentes antes de crear nuevos: `AmTopBar`, `AmCard`, `AmPress`, `AmBadge`, `AmAvatar`, `AmIconBtn`, `AmSegmented`, `AmSectionLabel`, `AmLoader`, `AmTextField`, `AmConfirmDialog`... (`AmBackBar` es legacy — no usar en pantallas nuevas).
- `AmLoader()` en lugar de `CircularProgressIndicator`.
- Widgets que animan su tamaño interno: envolver en `SizedBox` de tamaño fijo para no mover el layout externo.
- `AmStagger` solo para listas cortas sin scroll; dentro de `ListView` usar `AmAnimateIn(index: N)`.

## 4. Estado y lógica — Riverpod 3.x

- **Cero lógica de negocio en widgets/pantallas.** Pantallas solo `ref.watch`/`ref.read` + render.
- Flujo obligatorio: `Pantalla → Provider/Notifier → Repository → ApiClient/SDK`.
- **Prohibido `Supabase.instance` (o cualquier SDK) en widgets o pantallas** — incluso para signed URLs de Storage: eso va en un repository.
- Riverpod 3.x: no existe `StateProvider` — usar `Notifier`/`AsyncNotifier` + sus providers.
- Riverpod 3.x reutiliza la instancia del Notifier al invalidar (`build()` se re-ejecuta sobre el MISMO objeto). **Prohibido `late final` en campos asignados dentro de `build()`** — revienta con `LateInitializationError` en el primer `ref.invalidate` y el provider queda en `AsyncError` silencioso. Usar `late` a secas.
- Providers de UI state (búsqueda, filtros, tabs) viven en `features/<f>/providers/<f>_provider.dart`, no en la pantalla.
- Capturar el notifier ANTES de `Navigator.pop`/`await`: `final n = ref.read(p.notifier); Navigator.pop(context); n.accion();`
- Funciones async inline en `build`: prohibidas.

## 5. Utils y formatters

- Formateo de fechas/números/moneda SOLO vía `core/utils/formatters.dart` (`fmtCurrency`, `fmtDate`, `fmtSmartDate`, `fmtTime`...). Nunca `NumberFormat`/`DateFormat` directo en widgets.
- Código repetido en 2+ widgets → extraer a `core/utils/` en archivo por dominio (`date_formatters`, `number_formatters`, `reminder_utils`, `catalog_l10n`...). No crear un "utils.dart" cajón de sastre.
- Nombres de catálogo de BD: nunca mostrar el `name` crudo — traducir con `CatalogL10n` usando el `code`.

## 6. Manejo de errores hacia el usuario

- Los repositorios lanzan `ApiException` (con `statusCode`, `message`, `errorCode` del backend).
- La UI muestra errores SOLO vía `context.translateError(codeOrMessage)` (`core/utils/error_translator.dart`): si el `errorCode` es conocido → string localizada (`errModelBusy`, `errSessionExpired`...); si no → mostrar el `message` del backend tal cual.
- Código de error nuevo en el backend ⇒ agregar el case en `error_translator.dart` + claves `err*` en ambos ARB.
- Nunca `Text(e.toString())` ni exponer stack traces al usuario.
- Toda operación de red en providers debe capturar `ApiException` y dejar el error en el estado del provider — no `catch (_) {}` silencioso salvo operaciones fire-and-forget justificadas con comentario.

## 7. Realtime (Supabase)

- Listas principales (`contacts`, `policies`, `reminders`, `agent_notes`): patrón `AsyncNotifier` con `RealtimeChannel` + `ref.onDispose(unsubscribe)`.
  - INSERT: agregar solo si no existe (guard de echo optimista).
  - UPDATE con `is_active == false`: tratar como soft-delete (remover).
  - UPDATE normal: refetch por id y reemplazar.
  - DELETE: remover por id.
- Datos por pantalla (detalle): patrón dos providers — `FutureProvider.family` (datos) + `Provider.autoDispose.family<void>` que invalida; `autoDispose` cierra el canal al salir.
- Nunca crear canales Realtime fuera de providers (jamás en widgets).

## 8. Rendimiento

- `const` en constructores siempre que sea posible.
- Animaciones infinitas (`repeat()`): pausar/suspender cuando el widget no es visible o durante transiciones de ruta (patrón `AmAurora`); siempre `dispose()` de controllers y timers.
- `CustomPainter` con repaint frecuente: aislar con `RepaintBoundary`.
- `BackdropFilter`/blur: usar con moderación — es de lo más caro en GPU móvil.
- Providers derivados (`Provider<T>` computado) para filtrar/agrupar en memoria — no refetch de red al cambiar filtros de UI.
- Navegación de tabs: `StatefulShellRoute.indexedStack` + `NoTransitionPage` (no reconstruir tabs).
- No medir rendimiento en debug en dispositivo físico: usar `flutter run --profile`.

## 9. Seguridad

- En `.env` (empaquetado como asset) SOLO valores públicos: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (publishable), `API_BASE_URL`. **NUNCA** API keys privadas (Gemini, service role, FCM server keys) en la app — el binario es decompilable. Voz usa tokens efímeros del backend.
- No loggear tokens ni datos personales con `print`/`debugPrint`.

## 10. Calidad

- `flutter analyze` debe salir en 0 errores/warnings antes de dar por terminada una tarea.
- Tras editar ARB: `flutter gen-l10n`.
- No editar archivos generados (`lib/l10n/app_localizations*.dart`, `firebase_options.dart`).
