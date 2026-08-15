import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

enum ForgotPasswordStep { email, reset }

enum ForgotPasswordError {
  emptyEmail,
  invalidEmail,
  requestFailed,
  emptyFields,
  passwordMismatch,
  invalidCode,
}

class ForgotPasswordState {
  final ForgotPasswordStep step;
  final bool isLoading;
  final bool done;
  final ForgotPasswordError? error;
  final String email;

  ForgotPasswordState({
    this.step = ForgotPasswordStep.email,
    this.isLoading = false,
    this.done = false,
    this.error,
    this.email = '',
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    bool? isLoading,
    bool? done,
    ForgotPasswordError? error,
    bool clearError = false,
    String? email,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      done: done ?? this.done,
      error: clearError ? null : (error ?? this.error),
      email: email ?? this.email,
    );
  }
}

class ForgotPasswordNotifier extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() => ForgotPasswordState();

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> requestCode(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(error: ForgotPasswordError.emptyEmail);
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authProvider.notifier).requestPasswordReset(trimmed);
      state = state.copyWith(
        isLoading: false,
        step: ForgotPasswordStep.reset,
        email: trimmed,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: ForgotPasswordError.requestFailed,
      );
    }
  }

  Future<void> confirmReset({
    required String code,
    required String password,
    required String confirm,
  }) async {
    if (code.trim().isEmpty || password.isEmpty || confirm.isEmpty) {
      state = state.copyWith(error: ForgotPasswordError.emptyFields);
      return;
    }
    if (password != confirm) {
      state = state.copyWith(error: ForgotPasswordError.passwordMismatch);
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authProvider.notifier).confirmPasswordReset(
            email: state.email,
            token: code.trim(),
            newPassword: password,
          );
      state = state.copyWith(isLoading: false, done: true);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: ForgotPasswordError.invalidCode,
      );
    }
  }

  void backToEmail() =>
      state = state.copyWith(step: ForgotPasswordStep.email, clearError: true);
}

final forgotPasswordProvider =
    NotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(
        ForgotPasswordNotifier.new);
