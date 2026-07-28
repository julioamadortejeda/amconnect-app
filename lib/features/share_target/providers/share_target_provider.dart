import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import '../../feed/providers/ingest_provider.dart';

/// Destinos posibles para el contenido que llega desde el share sheet del SO.
///
/// `policyIngest` es el único que NO produce una nota: dispara el flujo
/// completo de alta de póliza (extracción, detección de cliente, catálogos y
/// recordatorios). El resto termina como nota en la base de conocimiento,
/// ligada o no a un cliente/póliza/recordatorio.
enum ShareDestinationType {
  policyIngest,
  global,
  client,
  policy,
  reminder,
}

/// Extensiones que el backend acepta para ingesta de archivos — debe reflejar
/// `ALLOWED_MIME_TYPES` en `storage.service.ts`. Validar aquí evita un viaje
/// de red a `ai/upload-url` que el backend rechazaría de todos modos (ej.
/// alguien comparte un .zip de "Exportar chat" de WhatsApp).
const _supportedFileExtensions = {
  'pdf', 'jpg', 'jpeg', 'png', 'webp', 'gif',
  'm4a', 'mp4', 'mp3', 'ogg', 'wav', 'webm',
};

/// Tope de caracteres para un `.txt` compartido (ej. "Exportar chat → sin
/// medios" de WhatsApp) — protege contra un historial descomunal sin
/// bloquear una conversación normal con un cliente. Se valida ANTES de
/// gastar la ingesta (que sí cobra cuota).
const _maxTextFileLength = 200000;

class ShareTargetState {
  final List<SharedFile>? sharedFiles;
  final String? sharedText;
  final ShareDestinationType destinationType;
  final String? selectedClientId;
  final String? selectedClientName;
  final String? selectedPolicyId;
  final String? selectedPolicyNumber;
  final String? selectedReminderId;
  final String? selectedReminderTitle;
  final bool isIngesting;
  final String? error;

  const ShareTargetState({
    this.sharedFiles,
    this.sharedText,
    this.destinationType = ShareDestinationType.global,
    this.selectedClientId,
    this.selectedClientName,
    this.selectedPolicyId,
    this.selectedPolicyNumber,
    this.selectedReminderId,
    this.selectedReminderTitle,
    this.isIngesting = false,
    this.error,
  });

  /// Primer archivo compartido (la app procesa uno por vez).
  SharedFile? get firstFile =>
      (sharedFiles != null && sharedFiles!.isNotEmpty) ? sharedFiles!.first : null;

  bool get hasFile => firstFile?.value != null && firstFile!.value!.isNotEmpty;

  bool get hasText => sharedText != null && sharedText!.trim().isNotEmpty;

  bool get hasContent => hasFile || hasText;

  /// El archivo compartido es un `.txt` — típicamente "Exportar chat → sin
  /// medios" de WhatsApp. Se procesa como texto (`ai/ingest-text`, se lee su
  /// contenido en `validate()`), no como archivo binario.
  bool get isTextFile => hasFile && _extensionOf(firstFile!) == 'txt';

  /// El archivo compartido no es un tipo que el backend acepte ingestar
  /// (ej. un `.zip` de "Exportar chat CON medios" de WhatsApp, un `.docx`,
  /// etc.). `.txt` no cuenta como no soportado — va por la ruta de texto.
  bool get isUnsupportedFile =>
      hasFile && !isTextFile && !_supportedFileExtensions.contains(_extensionOf(firstFile!));

  /// El alta automática de póliza solo corre sobre PDF o imagen — el backend
  /// rechaza cualquier otro mime en `ai/ingest-policy`.
  bool get canIngestAsPolicy {
    if (!hasFile) return false;
    final mime = _mimeOf(firstFile!);
    return mime == 'application/pdf' || mime.startsWith('image/');
  }

  /// Si falta elegir el destino concreto, o el archivo no es un tipo
  /// soportado, no hay nada que enviar.
  bool get canSubmit {
    if (!hasContent || isIngesting) return false;
    if (destinationType != ShareDestinationType.policyIngest && isUnsupportedFile) {
      return false;
    }
    return switch (destinationType) {
      ShareDestinationType.policyIngest => canIngestAsPolicy,
      ShareDestinationType.global => true,
      ShareDestinationType.client => selectedClientId != null,
      ShareDestinationType.policy => selectedPolicyId != null,
      ShareDestinationType.reminder => selectedReminderId != null,
    };
  }

  ShareTargetState copyWith({
    List<SharedFile>? sharedFiles,
    String? sharedText,
    ShareDestinationType? destinationType,
    String? selectedClientId,
    String? selectedClientName,
    String? selectedPolicyId,
    String? selectedPolicyNumber,
    String? selectedReminderId,
    String? selectedReminderTitle,
    bool? isIngesting,
    String? error,
  }) {
    return ShareTargetState(
      sharedFiles: sharedFiles ?? this.sharedFiles,
      sharedText: sharedText ?? this.sharedText,
      destinationType: destinationType ?? this.destinationType,
      selectedClientId: selectedClientId ?? this.selectedClientId,
      selectedClientName: selectedClientName ?? this.selectedClientName,
      selectedPolicyId: selectedPolicyId ?? this.selectedPolicyId,
      selectedPolicyNumber: selectedPolicyNumber ?? this.selectedPolicyNumber,
      selectedReminderId: selectedReminderId ?? this.selectedReminderId,
      selectedReminderTitle: selectedReminderTitle ?? this.selectedReminderTitle,
      isIngesting: isIngesting ?? this.isIngesting,
      error: error,
    );
  }
}

class ShareTargetNotifier extends Notifier<ShareTargetState> {
  @override
  ShareTargetState build() {
    return const ShareTargetState();
  }

  void setSharedFiles(List<SharedFile> files) {
    final textFiles = files
        .where((f) => f.type == SharedMediaType.TEXT || f.type == SharedMediaType.URL)
        .toList();
    final otherFiles = files
        .where((f) => f.type != SharedMediaType.TEXT && f.type != SharedMediaType.URL)
        .toList();

    final received = ShareTargetState(
      sharedFiles: otherFiles.isNotEmpty ? otherFiles : null,
      sharedText: textFiles.isNotEmpty ? textFiles.first.value : null,
    );

    // Un PDF/imagen casi siempre es una póliza: se pre-selecciona el alta
    // automática. Lo demás (texto, otros binarios) solo puede ser nota.
    state = received.canIngestAsPolicy
        ? received.copyWith(destinationType: ShareDestinationType.policyIngest)
        : received;
  }

  void setDestinationType(ShareDestinationType type) {
    state = state.copyWith(destinationType: type);
  }

  void selectClient({required String id, required String name}) {
    state = state.copyWith(
      selectedClientId: id,
      selectedClientName: name,
      destinationType: ShareDestinationType.client,
    );
  }

  void selectPolicy({required String id, required String number}) {
    state = state.copyWith(
      selectedPolicyId: id,
      selectedPolicyNumber: number,
      destinationType: ShareDestinationType.policy,
    );
  }

  void selectReminder({required String id, required String title}) {
    state = state.copyWith(
      selectedReminderId: id,
      selectedReminderTitle: title,
      destinationType: ShareDestinationType.reminder,
    );
  }

  void clearSelection() {
    state = const ShareTargetState();
  }

  /// Comprueba que el contenido siga disponible antes de cerrar la pantalla,
  /// y normaliza un `.txt` compartido a texto plano antes de despachar.
  ///
  /// Los dos SO entregan un `.txt` (ej. "Exportar chat → sin medios" de
  /// WhatsApp) de forma distinta: iOS lo manda como archivo (`isTextFile`,
  /// ver `_extensionOf`); Android lo clasifica como TEXT pero el plugin pone
  /// la RUTA del archivo en `value`, no su contenido (`getSharingUris` copia
  /// el content:// a caché y regresa el path — ver `getMediaType` en
  /// `FlutterSharingIntentPlugin.kt`). Detectar ese segundo caso es solo
  /// comprobar si `sharedText` apunta a un archivo real en disco.
  Future<bool> validate() async {
    final current = state;
    if (!current.canSubmit) return false;

    if (current.hasFile) {
      if (!await File(current.firstFile!.value!).exists()) {
        state = current.copyWith(error: 'SHARED_FILE_MISSING');
        return false;
      }
      if (current.isTextFile) {
        return _promoteFileToText(current, current.firstFile!.value!);
      }
      return true;
    }

    if (current.hasText && await File(current.sharedText!).exists()) {
      return _promoteFileToText(current, current.sharedText!);
    }

    return true;
  }

  /// Lee `path`, valida tamaño/contenido, y reemplaza el estado dejando el
  /// texto listo en `sharedText` — de ahí en adelante `dispatch()` no
  /// necesita saber que alguna vez fue un archivo.
  Future<bool> _promoteFileToText(ShareTargetState current, String path) async {
    final String content;
    try {
      content = await File(path).readAsString();
    } catch (_) {
      state = current.copyWith(error: 'SHARED_FILE_MISSING');
      return false;
    }
    if (content.trim().isEmpty) {
      state = current.copyWith(error: 'SHARED_FILE_MISSING');
      return false;
    }
    if (content.length > _maxTextFileLength) {
      state = current.copyWith(error: 'SHARED_TEXT_TOO_LARGE');
      return false;
    }

    state = ShareTargetState(
      sharedText: content,
      destinationType: current.destinationType,
      selectedClientId: current.selectedClientId,
      selectedClientName: current.selectedClientName,
      selectedPolicyId: current.selectedPolicyId,
      selectedPolicyNumber: current.selectedPolicyNumber,
      selectedReminderId: current.selectedReminderId,
      selectedReminderTitle: current.selectedReminderTitle,
    );
    return true;
  }

  /// Manda el contenido al pipeline de ingesta. A partir de aquí manda
  /// `IngestFlowOverlay` (montado en el shell): progreso, chat de
  /// confirmación, éxito y errores.
  ///
  /// Se llama DESPUÉS de cerrar la pantalla — los sheets del overlay usan el
  /// root navigator, el mismo que GoRouter, así que despachar antes del pop
  /// haría que ese pop cerrara el sheet en lugar de la pantalla.
  void dispatch() {
    final current = state;
    final ingest = ref.read(ingestProvider.notifier);
    final file = current.hasFile ? File(current.firstFile!.value!) : null;

    if (current.destinationType == ShareDestinationType.policyIngest) {
      if (file == null) return;
      ingest.processPolicy(file, _fileNameOf(current.firstFile!));
      return;
    }

    final contactId = current.destinationType == ShareDestinationType.client
        ? current.selectedClientId
        : null;
    final policyId = current.destinationType == ShareDestinationType.policy
        ? current.selectedPolicyId
        : null;
    final reminderId = current.destinationType == ShareDestinationType.reminder
        ? current.selectedReminderId
        : null;

    if (file != null) {
      ingest.processKnowledgeFile(
        file,
        _fileNameOf(current.firstFile!),
        contactId: contactId,
        policyId: policyId,
        reminderId: reminderId,
      );
    } else {
      ingest.processKnowledgeText(
        current.sharedText!,
        'text',
        contactId: contactId,
        policyId: policyId,
        reminderId: reminderId,
      );
    }
  }
}

/// Nombre con el que se sube el archivo. El pipeline de ingesta deriva el mime
/// de la extensión, así que si el share llegó sin ella se completa desde el
/// mimeType que reportó el sistema.
String _fileNameOf(SharedFile file) {
  final name = (file.value ?? '').split('/').last;
  if (name.contains('.')) return name;
  final ext = _extensionForMime(_mimeOf(file));
  return ext == null ? name : '$name.$ext';
}

/// Extensión del archivo compartido, sin el punto — de `mimeType` si el SO
/// lo declaró, si no del nombre del archivo.
String _extensionOf(SharedFile file) {
  final declared = file.mimeType;
  if (declared != null && declared.isNotEmpty) {
    final ext = _extensionForMime(declared);
    if (ext != null) return ext;
  }
  final name = (file.value ?? '').split('/').last;
  return name.contains('.') ? name.split('.').last.toLowerCase() : '';
}

String _mimeOf(SharedFile file) {
  final declared = file.mimeType;
  if (declared != null && declared.isNotEmpty) return declared;
  final path = (file.value ?? '').toLowerCase();
  return switch (path.split('.').last) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'heic' => 'image/heic',
    'webp' => 'image/webp',
    _ => file.type == SharedMediaType.IMAGE ? 'image/jpeg' : '',
  };
}

String? _extensionForMime(String mime) => switch (mime) {
      'application/pdf' => 'pdf',
      'image/png' => 'png',
      'image/jpeg' || 'image/heic' => 'jpg',
      'image/webp' => 'webp',
      _ => null,
    };

final shareTargetProvider = NotifierProvider<ShareTargetNotifier, ShareTargetState>(
  ShareTargetNotifier.new,
);
