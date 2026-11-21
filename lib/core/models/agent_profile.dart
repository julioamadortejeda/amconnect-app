import '../utils/formatters.dart';

/// Estado del consentimiento del Aviso de Privacidad (`privacy` de GET /agents/me).
class PrivacyConsent {
  const PrivacyConsent({
    this.acceptedVersion,
    this.acceptedAt,
    this.currentVersion = '',
    this.url = '',
    this.required = false,
  });

  /// Sin el campo `privacy` (backend viejo) NO se exige nada: nunca se bloquea
  /// al asesor por un backend que todavía no despliega esta función.
  static const notRequired = PrivacyConsent();

  final String? acceptedVersion;
  final String? acceptedAt;
  final String currentVersion;
  final String url;
  final bool required;

  /// Sin versión a la que aceptar no hay nada que mandar, aunque `required`
  /// viniera en true: se trata como no requerido.
  bool get mustAccept => required && currentVersion.isNotEmpty;

  factory PrivacyConsent.fromJson(Object? json) {
    if (json is! Map) return notRequired;
    return PrivacyConsent(
      acceptedVersion: json['acceptedVersion'] as String?,
      acceptedAt: json['acceptedAt'] as String?,
      currentVersion: json['currentVersion'] as String? ?? '',
      url: json['url'] as String? ?? '',
      required: json['required'] as bool? ?? false,
    );
  }
}

String? _validLocale(Object? v) => (v == 'es' || v == 'en') ? v as String : null;

class AgentProfile {
  const AgentProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.plan,
    required this.isActive,
    this.createdAt,
    this.locale,
    this.privacy = PrivacyConsent.notRequired,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String plan;
  final bool isActive;
  final String? createdAt;

  /// Idioma guardado en el backend ('es' | 'en'); null si nunca se sincronizó.
  final String? locale;
  final PrivacyConsent privacy;

  /// Compuerta del Aviso de Privacidad: true bloquea la app hasta aceptar.
  bool get mustAcceptPrivacy => privacy.mustAccept;

  AgentProfile copyWith({String? locale, PrivacyConsent? privacy}) => AgentProfile(
        id: id,
        fullName: fullName,
        email: email,
        phone: phone,
        plan: plan,
        isActive: isActive,
        createdAt: createdAt,
        locale: locale ?? this.locale,
        privacy: privacy ?? this.privacy,
      );

  String get initials => getInitials(fullName);

  factory AgentProfile.fromJson(Map<String, dynamic> json) => AgentProfile(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        plan: json['plan'] as String,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] as String?,
        // Valores heredados como 'es-MX' se tratan como no definidos: la app
        // vuelve a subir su idioma (solo 'es' o 'en' exactos son válidos).
        locale: _validLocale(json['locale']),
        privacy: PrivacyConsent.fromJson(json['privacy']),
      );
}
