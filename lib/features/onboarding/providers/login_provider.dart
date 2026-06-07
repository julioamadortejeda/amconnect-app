import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(isLoading: false);
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(isLoading: false);
  }

  Future<void> signInWithEmail(String email, String pass) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (email == 'admin@jacat.com' && pass == '123456') {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: LoginError.email);
    }
  }
}

final loginProvider = NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);