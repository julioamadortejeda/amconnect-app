import '../models/reminder.dart';
import '../models/reminder_setting.dart';
import '../models/reminder_type.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getAll();

  /// Recordatorios de una póliza, incluidos los ya cerrados — es el historial
  /// que se muestra en su detalle.
  Future<List<Reminder>> getByPolicy(String policyId);

  /// Configuración de anticipación de avisos, ya resuelta por el backend.
  Future<List<ReminderSetting>> getSettings();

  /// Guarda un valor y devuelve la configuración completa re-resuelta.
  /// `branchId` nulo apunta al default del asesor para ese tipo.
  Future<List<ReminderSetting>> updateSetting({
    required String typeCode,
    String? branchId,
    int? daysBefore,
    bool? isActive,
  });

  /// Quita la excepción de un ramo: vuelve a regir el default del asesor.
  Future<List<ReminderSetting>> removeSettingOverride({
    required String typeCode,
    required String branchId,
  });
  Future<Reminder?> getById(String id);
  Future<Reminder?> create({
    required String typeId,
    required String title,
    String? description,
    required DateTime dueDate,
    String? contactId,
    String? policyId,
    String? status,
  });
  Future<void> setDone(String id, bool isDone);
  Future<List<ReminderType>> getTypes();
  Future<Reminder?> updateStatus(String id, String statusCode, {String? comment});
  Future<Reminder?> reschedule(String id, DateTime dueDate);
  Future<Reminder?> updateDetails(String id, {String? title, String? description});
  Future<Reminder?> updateType(String id, String typeId);
  Future<Reminder?> updateRelations(String id, {String? contactId, String? policyId});
}
