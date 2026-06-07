import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amconnect/core/repositories/auth_repository.dart';

/// Implementación concreta de [AuthRepository] usando Supabase.
/// Si en el futuro se cambia a Firebase u otro proveedor,
/// solo se reemplaza esta clase — el resto del código no cambia.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  bool _googleInitialized = false;

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
  // ---------------------------------------------------------------------------

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      // TODO: uncomment and set your Web OAuth client ID from Google Cloud Console
      // This must match the Client ID in Supabase → Auth → Providers → Google
      // serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
    );
    _googleInitialized = true;
  }

  @override
  Future<void> signInWithGoogle() async {
    await _ensureGoogleInitialized();

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
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _client.auth.signOut();
  }
}

/// Provider del repositorio — inyecta el cliente de Supabase.
/// Cualquier Notifier que necesite auth consume este provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});
