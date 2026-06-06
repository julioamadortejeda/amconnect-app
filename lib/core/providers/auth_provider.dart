import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authUserProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((event) => event.session?.user);
});

class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      state = const AsyncData(null);
      return;
    }
    state = await AsyncValue.guard(() async {
      final googleAuth = await googleUser.authentication;
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
      );
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try { await GoogleSignIn().signOut(); } catch (_) {}
      await Supabase.instance.client.auth.signOut();
    });
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
