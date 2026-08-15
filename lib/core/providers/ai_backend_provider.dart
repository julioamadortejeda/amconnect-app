import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Backend de IA que procesó la última respuesta ('studio' | 'vertex').
/// Lo actualizan los notifiers de chat/voz al parsear cada respuesta del API
/// (el valor viaja en el payload — refleja lo que realmente corrió, no la
/// config al arrancar la app). Las pantallas lo muestran como badge
/// Free/Enterprise cuando kShowAiBackendBadge está activo.
class AiBackendNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? backend) {
    if (backend != null && backend.isNotEmpty && backend != state) {
      state = backend;
    }
  }
}

final aiBackendProvider =
    NotifierProvider<AiBackendNotifier, String?>(AiBackendNotifier.new);
