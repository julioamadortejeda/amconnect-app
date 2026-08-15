/// Cuánta anticipación quiere el asesor para un tipo de recordatorio.
///
/// Los valores llegan **ya resueltos** por el backend: `daysBefore` e
/// `isActive` son los que realmente va a usar el job, vengan de una fila
/// guardada o del valor de fábrica. La app no conoce los defaults.
class ReminderSetting {
  const ReminderSetting({
    required this.typeId,
    required this.typeCode,
    required this.typeName,
    required this.daysBefore,
    required this.isActive,
    required this.isCustomized,
    this.settingId,
    this.overrides = const [],
  });

  final String typeId;

  /// Código de catálogo (`PAYMENT`, `RENEWAL`…) — traducir con `CatalogL10n`.
  final String typeCode;
  final String typeName;
  final int daysBefore;
  final bool isActive;

  /// `false` cuando los valores vienen del default y no de una fila guardada.
  final bool isCustomized;
  final String? settingId;

  /// Excepciones por ramo que pisan el default de este tipo.
  final List<ReminderSettingOverride> overrides;

  factory ReminderSetting.fromJson(Map<String, dynamic> json) => ReminderSetting(
        typeId: json['typeId'] as String,
        typeCode: json['typeCode'] as String,
        typeName: json['typeName'] as String? ?? '',
        daysBefore: (json['daysBefore'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        isCustomized: json['isCustomized'] as bool? ?? false,
        settingId: json['settingId'] as String?,
        overrides: (json['overrides'] as List<dynamic>? ?? const [])
            .map((o) => ReminderSettingOverride.fromJson(o as Map<String, dynamic>))
            .toList(),
      );
}

class ReminderSettingOverride {
  const ReminderSettingOverride({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.daysBefore,
    required this.isActive,
  });

  final String id;
  final String branchId;
  final String branchName;
  final int daysBefore;
  final bool isActive;

  factory ReminderSettingOverride.fromJson(Map<String, dynamic> json) =>
      ReminderSettingOverride(
        id: json['id'] as String,
        branchId: json['branchId'] as String,
        branchName: json['branchName'] as String? ?? '',
        daysBefore: (json['daysBefore'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
      );
}
