import 'package:amconnect/features/assistant/providers/assistant_session_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release: sesión nueva por apertura; debug: se conserva', () {
    expect(shouldStartFreshAssistantSession(newSessionPerOpen: true), isTrue);
    expect(shouldStartFreshAssistantSession(newSessionPerOpen: false), isFalse);
  });

  test('la política por defecto sigue a kReleaseMode', () {
    expect(kAssistantNewSessionPerOpen, kReleaseMode);
    expect(shouldStartFreshAssistantSession(), kReleaseMode);
  });
}
