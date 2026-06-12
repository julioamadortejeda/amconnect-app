import 'package:amconnect/core/models/reminder.dart';
import 'package:amconnect/core/models/reminder_type.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getAll();
  Future<void> setDone(String id, bool isDone);
  Future<List<ReminderType>> getTypes();
}
