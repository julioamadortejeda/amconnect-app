import 'package:amconnect/core/models/agent_profile.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({Object? privacy = const _Absent(), String? locale}) => {
      'id': 'a1',
      'fullName': 'Ana',
      'email': 'a@x.com',
      'plan': 'trial',
      if (privacy is! _Absent) 'privacy': privacy,
      'locale': locale,
    };

class _Absent {
  const _Absent();
}

void main() {
  group('compuerta de privacidad', () {
    test('required=true con versión vigente bloquea', () {
      final p = AgentProfile.fromJson(_json(privacy: {
        'acceptedVersion': null,
        'acceptedAt': null,
        'currentVersion': '2026-11',
        'url': 'https://x.com/aviso',
        'required': true,
      }));
      expect(p.mustAcceptPrivacy, isTrue);
      expect(p.privacy.url, 'https://x.com/aviso');
    });

    test('required=false no bloquea', () {
      final p = AgentProfile.fromJson(_json(privacy: {
        'acceptedVersion': '2026-11',
        'acceptedAt': '2026-11-01T00:00:00Z',
        'currentVersion': '2026-11',
        'url': 'u',
        'required': false,
      }));
      expect(p.mustAcceptPrivacy, isFalse);
    });

    test('backend viejo sin campo privacy: no bloquea', () {
      expect(AgentProfile.fromJson(_json()).mustAcceptPrivacy, isFalse);
    });

    test('privacy mal formado: no bloquea', () {
      expect(AgentProfile.fromJson(_json(privacy: 'raro')).mustAcceptPrivacy, isFalse);
    });

    test('required sin currentVersion no bloquea (nada que aceptar)', () {
      final p = AgentProfile.fromJson(_json(privacy: {'required': true}));
      expect(p.mustAcceptPrivacy, isFalse);
    });

    test('locale se parsea y puede ser null', () {
      expect(AgentProfile.fromJson(_json(locale: 'en')).locale, 'en');
      expect(AgentProfile.fromJson(_json()).locale, isNull);
      expect(AgentProfile.fromJson(_json(locale: 'es-MX')).locale, isNull);
    });
  });
}
