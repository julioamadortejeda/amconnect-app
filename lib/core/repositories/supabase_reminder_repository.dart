import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder.dart';
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
