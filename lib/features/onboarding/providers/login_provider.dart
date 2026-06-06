import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/providers/auth_provider.dart';

enum LoginError { google, apple, email }

class LoginState {
  const LoginState({this.isLoading = false, this.error});
  final bool isLoading;
  final LoginError? error;

  LoginState copyWith({bool? isLoading, LoginError? error, bool clearError = false}) =>
      LoginState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await ref.read(authProvider.notifier).signInWithGoogle();
    final s = ref.read(authProvider);
    state = LoginState(isLoading: false, error: s.hasError ? LoginError.google : null);
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await ref.read(authProvider.notifier).signInWithApple();
    final s = ref.read(authProvider);
    state = LoginState(isLoading: false, error: s.hasError ? LoginError.apple : null);
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await ref.read(authProvider.notifier).signIn(email: email, password: password);
    final s = ref.read(authProvider);
    state = LoginState(isLoading: false, error: s.hasError ? LoginError.email : null);
  }
}

final loginProvider = NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);
