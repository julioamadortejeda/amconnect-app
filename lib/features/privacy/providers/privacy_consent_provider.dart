import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../account/providers/account_provider.dart';

class PrivacyConsentState {
  const PrivacyConsentState({
    this.checked = false,
    this.sensitiveChecked = false,
    this.submitting = false,
    this.error,
  });

  /// Casilla 1: aviso + transferencias. Casilla 2: datos sensibles. Ambas obligatorias.
  final bool checked;
  final bool sensitiveChecked;
  final bool submitting;

  /// Código/mensaje para `context.translateError`.
  final String? error;

  bool get canAccept => checked && sensitiveChecked && !submitting;

  PrivacyConsentState copyWith({bool? checked, bool? sensitiveChecked, bool? submitting, String? error, bool clearError = false}) =>
      PrivacyConsentState(
        checked: checked ?? this.checked,
        sensitiveChecked: sensitiveChecked ?? this.sensitiveChecked,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : (error ?? this.error),
      );
}

class PrivacyConsentNotifier extends Notifier<PrivacyConsentState> {
  @override
  PrivacyConsentState build() => const PrivacyConsentState();

  void setChecked(bool value) => state = state.copyWith(checked: value, clearError: true);

  void setSensitiveChecked(bool value) =>
      state = state.copyWith(sensitiveChecked: value, clearError: true);

  /// true si el backend registró la aceptación; en error deja el mensaje en el
  /// estado y el botón vuelve a quedar habilitado para reintentar.
  Future<bool> accept() async {
    if (!state.canAccept) return false;
    state = state.copyWith(submitting: true, clearError: true);
    try {
      await ref.read(agentProfileProvider.notifier).acceptPrivacy();
      state = state.copyWith(submitting: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(submitting: false, error: mapApiError(e));
      return false;
    }
  }
}

final privacyConsentProvider =
    NotifierProvider.autoDispose<PrivacyConsentNotifier, PrivacyConsentState>(
        PrivacyConsentNotifier.new);
