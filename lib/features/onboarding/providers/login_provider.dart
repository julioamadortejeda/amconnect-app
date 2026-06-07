import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/providers/auth_provider.dart';

enum LoginError { google, apple, email }

class LoginState {
  final bool isLoading;
  final LoginError? error;

  LoginState({
    this.isLoading = false,
    this.error,
  });

  LoginState copyWith({
    bool? isLoading,
    LoginError? error,
    bool clearError = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => LoginState();

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: LoginError.google);
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authProvider.notifier).signInWithApple();
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: LoginError.apple);
    }
  }
}

final loginProvider = NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);