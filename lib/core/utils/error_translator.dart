import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'api_error_mapper.dart' show kErrRefSeparator;

extension ErrorTranslator on BuildContext {
  /// Traduce códigos de error conocidos a localizaciones del sistema.
  /// Si no coincide con ningún código conocido, devuelve el mensaje original
  /// (fallback del contrato: la app muestra el `error` del backend tal cual).
  ///
  /// Si la string trae un sufijo `#ref=xxxxxxxx` (agregado por
  /// `mapApiError` cuando el backend persistió el error en `error_logs`),
  /// se muestra debajo como código de referencia para soporte.
  String translateError(String? errorCodeOrMessage) {
    if (errorCodeOrMessage == null) return '';
    final l10n = AppLocalizations.of(this);
    if (l10n == null) return errorCodeOrMessage;

    var key = errorCodeOrMessage;
    String? ref;
    final sepIndex = key.indexOf(kErrRefSeparator);
    if (sepIndex != -1) {
      ref = key.substring(sepIndex + kErrRefSeparator.length);
      key = key.substring(0, sepIndex);
    }

    final translated = switch (key) {
      'AI_PROVIDER_BUSY' || 'errModelBusy' => l10n.errModelBusy,
      'SESSION_EXPIRED' || 'errSessionExpired' => l10n.errSessionExpired,
      'RESOURCE_NOT_FOUND' || 'errNotFound' => l10n.errNotFound,
      'CONNECTION_FAILED' || 'errNetwork' => l10n.errNetwork,
      'QUOTA_EXCEEDED' => l10n.errQuotaExceeded,
      'SUBSCRIPTION_REQUIRED' => l10n.errSubscriptionRequired,
      'VALIDATION_FAILED' => l10n.errValidationFailed,
      'RESOURCE_CONFLICT' => l10n.errConflict,
      'ACCESS_DENIED' => l10n.errAccessDenied,
      'AI_ERROR' || 'AI_INVOCATION_FAILED' => l10n.errAiFailed,
      'UPLOAD_FAILED' => l10n.errUploadFailed,
      'SHARED_FILE_MISSING' => l10n.errSharedFileMissing,
      'SHARED_TEXT_TOO_LARGE' => l10n.errSharedTextTooLarge,
      'INTERNAL_ERROR' || 'errUnknown' => l10n.errUnknown,
      'MIC_PERMISSION_DENIED' => l10n.voiceChatPermissionDenied,
      _ => key,
    };

    if (ref != null && ref.isNotEmpty) {
      return '$translated\n${l10n.errRefCode(ref)}';
    }
    return translated;
  }
}
