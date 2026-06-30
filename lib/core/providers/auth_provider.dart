import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../repositories/supabase_auth_repository.dart';
import '../repositories/supabase_agent_repository.dart';

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

  Future<void> signUp({required String email, required String password}) =>
      _repo.signUp(email: email, password: password);

  Future<void> signInWithGoogle() => _repo.signInWithGoogle();

  Future<void> signInWithApple() => _repo.signInWithApple();

  Future<void> signOut() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ref.read(agentRepositoryProvider).deregisterDeviceToken(token: token);
      }
    } catch (e) {
      // Ignoramos errores de red o FCM al desasociar el token en logout para no bloquear la salida del usuario.
      debugPrint("Warning cleaning up FCM token on logout: $e");
    }
    await _repo.signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, void>(AuthNotifier.new);
