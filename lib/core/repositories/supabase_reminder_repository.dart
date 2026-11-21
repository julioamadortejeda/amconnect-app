import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder.dart';
import '../models/reminder_setting.dart';
import '../models/reminder_type.dart';
import '../network/api_client.dart';
import 'reminder_repository.dart';

class SupabaseReminderRepository implements ReminderRepository {
  SupabaseReminderRepository(this._client);
  final ApiClient _client;

  /// Tamaño de página máximo que acepta el backend (`shared/pagination.ts`).
  static const _pageSize = 100;

  /// Freno de seguridad: 50 páginas = 5,000 recordatorios. Si el backend
  /// respondiera `hasMore: true` para siempre, no queremos un bucle sin fin.
  static const _maxPages = 50;

  @override
  Future<List<Reminder>> getAll() => _getAllPages('reminders');

  /// Recorre todas las páginas de un listado de recordatorios.
  ///
  /// Antes se pedía una sola página de 100. El backend ordena por
  /// `created_at desc`, así que con más de 100 la Agenda perdía en silencio
  /// los más viejos — justo los PAYMENT/RENEWAL que genera el cron. El
  /// calendario y los conteos del dashboard necesitan la lista completa, por
  /// eso se itera aquí en vez de paginar por scroll.
  Future<List<Reminder>> _getAllPages(String basePath) async {
    final sep = basePath.contains('?') ? '&' : '?';
    final all = <Reminder>[];
    final seen = <String>{};
    for (var page = 1; page <= _maxPages; page++) {
      final res = await _client.get('$basePath${sep}page=$page&pageSize=$_pageSize');
      final wrapper = res['data'] as Map<String, dynamic>;
      final items = wrapper['data'] as List<dynamic>;
      for (final e in items) {
        final r = Reminder.fromJson(e as Map<String, dynamic>);
        // Un recordatorio creado entre página y página recorre el orden y
        // repetiría uno ya leído.
        if (seen.add(r.id)) all.add(r);
      }
      final hasMore = wrapper['hasMore'] as bool? ?? false;
      if (!hasMore || items.isEmpty) break;
    }
    return all;
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
    return _getAllPages('reminders?policyId=$policyId');
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

  /// `PATCH reminders/:id/done` — sin cuerpo. Antes se mandaba
  /// `PATCH reminders/:id {isDone}`, pero `isDone` no existe en el esquema
  /// Zod del backend: se descartaba en silencio y respondía 200 sin guardar.
  @override
  Future<Reminder?> markDone(String id) async {
    final res = await _client.patch('reminders/$id/done');
    final data = res['data'] as Map<String, dynamic>?;
    return data != null ? Reminder.fromJson(data) : null;
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
