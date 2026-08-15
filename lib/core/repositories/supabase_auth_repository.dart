import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

/// Implementación concreta de [AuthRepository] usando Supabase.
/// Si en el futuro se cambia a Firebase u otro proveedor,
/// solo se reemplaza esta clase — el resto del código no cambia.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  // ---------------------------------------------------------------------------
  // Auth state
  // ---------------------------------------------------------------------------

  @override
  Stream<User?> get onAuthStateChange =>
      _client.auth.onAuthStateChange.map((e) => e.session?.user);

  // ---------------------------------------------------------------------------
  // Email / password
  // ---------------------------------------------------------------------------

  @override
  Future<void> signIn({required String email, required String password}) =>
      _client.auth.signInWithPassword(email: email, password: password);

  @override
  Future<void> signUp({required String email, required String password}) =>
      _client.auth.signUp(email: email, password: password);

  @override
  Future<void> requestPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email);

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email,
      token: token,
    );
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ---------------------------------------------------------------------------
  // Google  (google_sign_in ^7.x)
  //
  // v7 breaking changes vs v6:
  //  • GoogleSignIn() constructor removed → use GoogleSignIn.instance singleton
  //  • signIn() removed                  → use authenticate()
  //  • GoogleSignInAuthentication.accessToken removed (moved to authorization)
  //  • googleUser.authentication is now a SYNC getter (was Future in v6)
  //  • initialize() must be called before authenticate()
  //
  // Supabase requirement:
  //  The idToken audience must match the Web OAuth client ID configured in
  //  your Supabase project (Authentication → Providers → Google → Client ID).
  //  Set that same value as serverClientId in initialize() below, or configure
  //  GIDServerClientID in Info.plist (iOS) / google-services.json (Android).
  //
  // Nonce:
  //  El SDK nativo de Google mete un claim `nonce` en el idToken aunque no se
  //  lo pidas explícitamente, y Supabase rechaza el intercambio si el token
  //  trae `nonce` y tú no le mandas uno ("Passed nonce and nonce in id_token
  //  should either both exist or not."). Patrón oficial: nonce crudo (random)
  //  → SHA-256 → se manda hasheado a Google (initialize) para que quede en el
  //  claim del token; el crudo se manda tal cual a signInWithIdToken, que lo
  //  hashea internamente para comparar. Debe regenerarse en cada intento
  //  (un nonce reusado no cumple su propósito anti-replay) — por eso
  //  initialize() se re-llama en cada signInWithGoogle() en vez de una sola
  //  vez al arrancar.
  // ---------------------------------------------------------------------------

  @override
  Future<void> signInWithGoogle() async {
    final rawNonce = _generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    await GoogleSignIn.instance.initialize(
      // Web OAuth client ID del proyecto GCP (amconnect-jacatsoft). Debe
      // coincidir con el client_id configurado en Supabase Auth → Google.
      serverClientId:
          '209849163943-tnlpoo835d1ijmjc3umaesqco07o5qti.apps.googleusercontent.com',
      nonce: hashedNonce,
    );

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } on PlatformException catch (e) {
      // User dismissed the sign-in dialog — not an error
      if (e.code == 'sign_in_canceled' || e.code == 'sign_in_failed') return;
      rethrow;
    }

    // In v7, authentication is a sync getter (was Future<> in v6)
    final String? idToken = googleUser.authentication.idToken;
    if (idToken == null) throw Exception('Google Sign In: idToken is null');

    // accessToken is optional for Supabase but can be provided for extra
    // Google API scopes. In v7 it lives in authorizationClient, not in authentication.
    String? accessToken;
    try {
      final auth =
          await googleUser.authorizationClient.authorizationForScopes([]);
      accessToken = auth?.accessToken;
    } catch (_) {
      // accessToken is optional — proceed without it
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
      nonce: rawNonce,
    );
  }

  // ---------------------------------------------------------------------------
  // Apple
  // ---------------------------------------------------------------------------

  @override
  Future<void> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    if (credential.identityToken == null) {
      throw Exception('Apple Sign In: identityToken is null');
    }
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: credential.identityToken!,
    );
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // fire-and-forget: inofensivo si el usuario nunca inició sesión con Google
      // (initialize() corre por intento en signInWithGoogle, no una sola vez) —
      // este catch cubre el caso en que el SDK de Google no esté inicializado.
    }
    await _client.auth.signOut();
  }

  /// Nonce aleatorio para el intercambio OIDC con Google — ver comentario en
  /// signInWithGoogle(). Debe regenerarse en cada intento.
  String _generateRawNonce() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => random.nextInt(256)));
  }
}

/// Provider del repositorio — inyecta el cliente de Supabase.
/// Cualquier Notifier que necesite auth consume este provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});
