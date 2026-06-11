import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/models/reminder.dart';
import 'package:amconnect/core/network/api_client.dart';
import 'package:amconnect/core/repositories/reminder_repository.dart';

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
}

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return SupabaseReminderRepository(ref.read(apiClientProvider));
});
