import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amconnect/core/repositories/auth_repository.dart';
import 'package:amconnect/core/repositories/supabase_auth_repository.dart';

/// Stream del usuario autenticado — escuchado por el router para redirigir.
final authUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

/// Notifier de acciones de auth.
/// Solo conoce [AuthRepository] — no sabe nada de Supabase, Google, Apple, etc.
/// Los métodos lanzan excepción en error; la pantalla la captura vía ref.listen.
class AuthNotifier extends Notifier<void> {
  late final AuthRepository _repo;

  @override
  void build() {
    _repo = ref.read(authRepositoryProvider);
  }

  Future<void> signIn({required String email, required String password}) =>
      _repo.signIn(email: email, password: password);

  Future<void> signInWithGoogle() => _repo.signInWithGoogle();

  Future<void> signInWithApple() => _repo.signInWithApple();

  Future<void> signOut() => _repo.signOut();
}

final authProvider = NotifierProvider<AuthNotifier, void>(AuthNotifier.new);
