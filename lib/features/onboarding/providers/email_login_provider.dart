import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/providers/auth_provider.dart';

enum EmailLoginError { emptyFields, wrongCredentials }

class EmailLoginState {
  final bool isLoading;
  final EmailLoginError? error;

  EmailLoginState({
    this.isLoading = false,
    this.error,
  });

  EmailLoginState copyWith({
    bool? isLoading,
    EmailLoginError? error,
    bool clearError = false,
  }) {
    return EmailLoginState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class EmailLoginNotifier extends Notifier<EmailLoginState> {
  @override
  EmailLoginState build() => EmailLoginState();

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(error: EmailLoginError.emptyFields);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authProvider.notifier).signIn(email: email, password: password);
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: EmailLoginError.wrongCredentials);
    }
  }
}

final emailLoginProvider = NotifierProvider<EmailLoginNotifier, EmailLoginState>(EmailLoginNotifier.new);