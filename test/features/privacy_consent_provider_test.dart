import 'package:amconnect/core/models/agent_profile.dart';
import 'package:amconnect/core/network/api_client.dart';
import 'package:amconnect/core/repositories/agent_repository.dart';
import 'package:amconnect/core/repositories/supabase_agent_repository.dart';
import 'package:amconnect/features/account/providers/account_provider.dart';
import 'package:amconnect/features/privacy/providers/privacy_consent_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements AgentRepository {
  _FakeRepo({this.acceptError});
  final ApiException? acceptError;
  final locales = <String>[];
  String? acceptedVersion;
  bool? sentNotice;
  bool? sentSensitive;

  static const _pending = PrivacyConsent(currentVersion: 'v1', url: 'u', required: true);

  @override
  Future<AgentProfile> getMe() async => const AgentProfile(
      id: '1', fullName: 'Ana', email: 'a@x.com', plan: 'trial', isActive: true, privacy: _pending);

  @override
  Future<PrivacyConsent> acceptPrivacy(String version,
      {required bool acceptedNotice, required bool acceptedSensitive}) async {
    if (acceptError != null) throw acceptError!;
    acceptedVersion = version;
    sentNotice = acceptedNotice;
    sentSensitive = acceptedSensitive;
    return const PrivacyConsent(currentVersion: 'v1', acceptedVersion: 'v1', url: 'u');
  }

  @override
  Future<void> updateLocale(String locale) async => locales.add(locale);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test('aceptar: manda la versión vigente y desbloquea', () async {
    final repo = _FakeRepo();
    final c = ProviderContainer(overrides: [agentRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    // perfil cargado
    final profile = await c.read(agentProfileProvider.future);
    expect(profile.mustAcceptPrivacy, isTrue);
    final n = c.read(privacyConsentProvider.notifier);
    expect(await n.accept(), isFalse); // sin casillas no hace nada
    n.setChecked(true);
    expect(c.read(privacyConsentProvider).canAccept, isFalse); // falta la 2
    n.setChecked(true);
    n.setSensitiveChecked(true);
    expect(await n.accept(), isTrue);
    expect(repo.acceptedVersion, 'v1');
    expect(repo.sentNotice, isTrue);
    expect(repo.sentSensitive, isTrue);
    expect(c.read(agentProfileProvider).value!.mustAcceptPrivacy, isFalse);
  });

  test('error del backend: queda en el estado y permite reintentar', () async {
    final repo = _FakeRepo(
        acceptError: const ApiException(statusCode: 422, message: 'x', errorCode: 'VALIDATION_FAILED'));
    final c = ProviderContainer(overrides: [agentRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    await c.read(agentProfileProvider.future);
    final n = c.read(privacyConsentProvider.notifier);
    n.setChecked(true);
    n.setSensitiveChecked(true);
    expect(await n.accept(), isFalse);
    final s = c.read(privacyConsentProvider);
    expect(s.error, 'VALIDATION_FAILED');
    expect(s.canAccept, isTrue);
  });

  test('locale null en el backend: se sube el idioma de la app', () async {
    final repo = _FakeRepo();
    final c = ProviderContainer(overrides: [agentRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    await c.read(agentProfileProvider.future);
    await Future<void>.delayed(Duration.zero);
    expect(repo.locales.length, 1);
    expect(['es', 'en'], contains(repo.locales.single));
  });
}
