import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

enum RegisterError { emptyFields, passwordMismatch, serverError }

class RegisterState {
  final bool isLoading;
  final RegisterError? error;

  RegisterState({
    this.isLoading = false,
    this.error,
  });

  RegisterState copyWith({
    bool? isLoading,
    RegisterError? error,
    bool clearError = false,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RegisterNotifier extends Notifier<RegisterState> {
  @override
  RegisterState build() => RegisterState();

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> signUp(String email, String pass, String confirm) async {
    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      state = state.copyWith(error: RegisterError.emptyFields);
      return;
    }
    if (pass != confirm) {
      state = state.copyWith(error: RegisterError.passwordMismatch);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authProvider.notifier).signUp(email: email, password: pass);
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: RegisterError.serverError);
    }
  }
}

final registerProvider = NotifierProvider<RegisterNotifier, RegisterState>(RegisterNotifier.new);
