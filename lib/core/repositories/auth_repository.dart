import 'package:supabase_flutter/supabase_flutter.dart';

/// Interfaz abstracta de autenticación.
/// La lógica de negocio (Notifiers) depende SOLO de esta interfaz,
/// nunca del SDK concreto (Supabase, Firebase, etc.).
abstract class AuthRepository {
  /// Stream del usuario actualmente autenticado.
  Stream<User?> get onAuthStateChange;

  /// Inicio de sesión con email y contraseña.
  Future<void> signIn({required String email, required String password});

  /// Registro de nuevo usuario con email y contraseña.
  Future<void> signUp({required String email, required String password});

  /// Envía un código de recuperación de 6 dígitos al correo del usuario.
  Future<void> requestPasswordReset(String email);

  /// Verifica el código de recuperación y establece la nueva contraseña.
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  });

  /// Inicio de sesión con cuenta Google.
  Future<void> signInWithGoogle();

  /// Inicio de sesión con Apple ID.
  Future<void> signInWithApple();

  /// Cierre de sesión.
  Future<void> signOut();
}
