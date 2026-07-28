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

  /// El alta automática de póliza solo corre sobre PDF o imagen — el backend
  /// rechaza cualquier otro mime en `ai/ingest-policy`.
  bool get canIngestAsPolicy {
    if (!hasFile) return false;
    final mime = _mimeOf(firstFile!);
    return mime == 'application/pdf' || mime.startsWith('image/');
  }

  /// Si falta elegir el destino concreto, no hay nada que enviar.
  bool get canSubmit {
    if (!hasContent || isIngesting) return false;
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

  /// Comprueba que el contenido siga disponible antes de cerrar la pantalla.
  /// Si el archivo ya no está en disco deja el motivo en `state.error` para
  /// que la pantalla lo traduzca, y devuelve `false`.
  Future<bool> validate() async {
    final current = state;
    if (!current.canSubmit) return false;

    if (current.hasFile && !await File(current.firstFile!.value!).exists()) {
      state = current.copyWith(error: 'SHARED_FILE_MISSING');
      return false;
    }
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
