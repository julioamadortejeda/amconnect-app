import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';

extension ErrorTranslator on BuildContext {
  /// Traduce códigos de error conocidos a localizaciones del sistema.
  /// Si no coincide con ningún código conocido, devuelve el mensaje original.
  String translateError(String? errorCodeOrMessage) {
    if (errorCodeOrMessage == null) return '';
    final l10n = AppLocalizations.of(this);
    if (l10n == null) return errorCodeOrMessage;

    return switch (errorCodeOrMessage) {
      'AI_PROVIDER_BUSY' || 'errModelBusy' => l10n.errModelBusy,
      'SESSION_EXPIRED' || 'errSessionExpired' => l10n.errSessionExpired,
      'RESOURCE_NOT_FOUND' || 'errNotFound' => l10n.errNotFound,
      'CONNECTION_FAILED' || 'errNetwork' => l10n.errNetwork,
      'errUnknown' => l10n.errUnknown,
      _ => errorCodeOrMessage,
    };
  }
}
