import 'package:flutter/foundation.dart';

/// ÚNICO lugar donde se decide si el asistente arranca una sesión nueva cada
/// vez que el asesor lo abre.
///
/// - Release: sesión nueva por apertura (el historial no sobrevive a salir).
/// - Debug: el historial se conserva al salir y volver — comodidad de
///   desarrollo para no repetir la conversación en cada hot restart de pantalla.
const bool kAssistantNewSessionPerOpen = kReleaseMode;

/// [newSessionPerOpen] se inyecta para poder probar ambas políticas.
bool shouldStartFreshAssistantSession({bool newSessionPerOpen = kAssistantNewSessionPerOpen}) =>
    newSessionPerOpen;
