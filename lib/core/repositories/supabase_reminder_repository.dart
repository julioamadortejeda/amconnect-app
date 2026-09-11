import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder.dart';
import '../models/reminder_setting.dart';
import '../models/reminder_type.dart';
import '../network/api_client.dart';
import 'reminder_repository.dart';

class SupabaseReminderRepository implements ReminderRepository {
  SupabaseReminderRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<Reminder>> getAll() async {
    final res = await _client.get('reminders?pageSize=100');
    final wrapper = res['data'] as Map<String, dynamic>;
    final items = wrapper['data'] as List<dynamic>;
    return items.map((e) => Reminder.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Reminder>> search(String query) async {
    final res = await _client.get(
        'reminders?query=${Uri.encodeQueryComponent(query)}&pageSize=50');
    final wrapper = res['data'] as Map<String, dynamic>;
    final items = wrapper['data'] as List<dynamic>;
    return items.map((e) => Reminder.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Reminder>> getByPolicy(String policyId) async {
    final res = await _client.get('reminders?policyId=$policyId&pageSize=100');
    final wrapper = res['data'] as Map<String, dynamic>;
    final items = wrapper['data'] as List<dynamic>;
    return items.map((e) => Reminder.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ReminderSetting>> getSettings() async {
    final res = await _client.get('reminders/settings');
    final items = res['data'] as List<dynamic>;
    return items.map((e) => ReminderSetting.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ReminderSetting>> updateSetting({
    required String typeCode,
    String? branchId,
    int? daysBefore,
    bool? isActive,
  }) async {
    final res = await _client.patch('reminders/settings', body: {
      'reminderTypeCode': typeCode,
      if (branchId != null) 'branchId': branchId,
      if (daysBefore != null) 'daysBefore': daysBefore,
      if (isActive != null) 'isActive': isActive,
    });
    final items = res['data'] as List<dynamic>;
    return items.map((e) => ReminderSetting.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ReminderSetting>> removeSettingOverride({
    required String typeCode,
    required String branchId,
  }) async {
    // ApiClient.delete no devuelve cuerpo, así que se relee la configuración.
    // Es una acción poco frecuente: no vale la pena cambiar el cliente
    // compartido por este único caso.
    await _client.delete('reminders/settings/$typeCode/branches/$branchId');
    return getSettings();
  }

  @override
  Future<Reminder?> create({
    required String typeId,
    required String title,
    String? description,
    required DateTime dueDate,
    String? contactId,
    String? policyId,
    String? status,
  }) async {
    final res = await _client.post('reminders', body: {
      'typeId': typeId,
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'dueDate': dueDate.toUtc().toIso8601String(),
      if (contactId != null) 'contactId': contactId,
      if (policyId != null) 'policyId': policyId,
      if (status != null) 'status': status,
    });
    final data = res['data'] as Map<String, dynamic>?;
    return data != null ? Reminder.fromJson(data) : null;
  }

  @override
  Future<void> setDone(String id, bool isDone) async {
    await _client.patch('reminders/$id', body: {'isDone': isDone});
  }

  @override
  Future<Reminder?> updateStatus(String id, String statusCode, {String? comment}) async {
    final body = <String, dynamic>{'status': statusCode};
    if (comment != null && comment.isNotEmpty) body['comment'] = comment;
    final res = await _client.patch('reminders/$id', body: body);
    final data = res['data'] as Map<String, dynamic>?;
    return data != null ? Reminder.fromJson(data) : null;
  }

  @override
  Future<Reminder?> reschedule(String id, DateTime dueDate) async {
    final res = await _client.patch('reminders/$id', body: {
      'dueDate': dueDate.toUtc().toIso8601String(),
    });
    final data = res['data'] as Map<String, dynamic>?;
    return data != null ? Reminder.fromJson(data) : null;
  }

  @override
  Future<Reminder?> getById(String id) async {
    final res = await _client.get('reminders/$id');
    final data = res['data'] as Map<String, dynamic>?;
    return data != null ? Reminder.fromJson(data) : null;
  }

  @override
  Future<Reminder?> updateDetails(String id, {String? title, String? description}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (body.isEmpty) return null;
    final res = await _client.patch('reminders/$id', body: body);
    final data = res['data'] as Map<String, dynamic>?;
    return data != null ? Reminder.fromJson(data) : null;
  }

  @override
  Future<Reminder?> updateType(String id, String typeId) async {
    final res = await _client.patch('reminders/$id', body: {'typeId': typeId});
    final data = res['data'] as Map<String, dynamic>?;
    return data != null ? Reminder.fromJson(data) : null;
  }

  @override
  Future<Reminder?> updateRelations(String id, {String? contactId, String? policyId}) async {
    final res = await _client.patch('reminders/$id', body: {
      'contactId': contactId,
      'policyId': policyId,
    });
    final data = res['data'] as Map<String, dynamic>?;
    return data != null ? Reminder.fromJson(data) : null;
  }

  @override
  Future<List<ReminderType>> getTypes() async {
    final res = await _client.get('catalog/reminder-types');
    final items = res['data'] as List<dynamic>;
    return items
        .map((e) => ReminderType.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return SupabaseReminderRepository(ref.read(apiClientProvider));
});
