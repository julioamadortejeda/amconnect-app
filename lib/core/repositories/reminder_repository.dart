import '../models/reminder.dart';
import '../models/reminder_type.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getAll();
  Future<Reminder?> getById(String id);
  Future<void> setDone(String id, bool isDone);
  Future<List<ReminderType>> getTypes();
  Future<Reminder?> updateStatus(String id, String statusCode, {String? comment});
  Future<Reminder?> reschedule(String id, DateTime dueDate);
  Future<Reminder?> updateDetails(String id, {String? title, String? description});
  Future<Reminder?> updateType(String id, String typeId);
}
