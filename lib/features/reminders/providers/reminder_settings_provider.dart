import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/catalog.dart';
import '../../../core/models/reminder_setting.dart';
import '../../../core/network/api_client.dart';
import '../../../core/repositories/supabase_reminder_repository.dart';
import '../../clients/providers/catalog_provider.dart';

/// Configuración de anticipación de avisos. Los valores llegan ya resueltos
/// del backend, así que aquí no hay defaults ni cálculo — solo estado.
class ReminderSettingsNotifier extends AsyncNotifier<List<ReminderSetting>> {
  @override
  Future<List<ReminderSetting>> build() async {
    return ref.read(reminderRepositoryProvider).getSettings();
  }

  /// Guarda un cambio y adopta la configuración completa que responde el
  /// backend, en vez de recargar: la respuesta ya viene re-resuelta.
  Future<void> save({
    required String typeCode,
    String? branchId,
    int? daysBefore,
    bool? isActive,
  }) async {
    try {
      final updated = await ref.read(reminderRepositoryProvider).updateSetting(
            typeCode: typeCode,
            branchId: branchId,
            daysBefore: daysBefore,
            isActive: isActive,
          );
      state = AsyncData(updated);
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Quita la excepción de un ramo; ese ramo vuelve a seguir el default.
  Future<void> removeOverride({
    required String typeCode,
    required String branchId,
  }) async {
    try {
      final updated = await ref.read(reminderRepositoryProvider).removeSettingOverride(
            typeCode: typeCode,
            branchId: branchId,
          );
      state = AsyncData(updated);
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Ramos que todavía NO tienen excepción para ese tipo de aviso — los que sí
/// tienen ya no se ofrecen para no crear dos reglas del mismo ramo.
final availableBranchesForSettingProvider =
    Provider.family<List<Branch>, String>((ref, typeCode) {
  final branches = ref.watch(branchesProvider).asData?.value ?? const <Branch>[];
  final settings = ref.watch(reminderSettingsProvider).asData?.value ?? const <ReminderSetting>[];
  final setting = settings.where((s) => s.typeCode == typeCode).firstOrNull;
  final taken = (setting?.overrides ?? const <ReminderSettingOverride>[])
      .map((o) => o.branchId)
      .toSet();
  return branches.where((b) => !taken.contains(b.id)).toList();
});

final reminderSettingsProvider =
    AsyncNotifierProvider<ReminderSettingsNotifier, List<ReminderSetting>>(
  ReminderSettingsNotifier.new,
);
