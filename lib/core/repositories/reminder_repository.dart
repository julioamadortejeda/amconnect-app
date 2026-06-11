import 'package:amconnect/core/models/reminder.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getAll();
  Future<void> setDone(String id, bool isDone);
}
