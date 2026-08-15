import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final notificationPermissionStatusProvider =
    FutureProvider.autoDispose<PermissionStatus>((ref) {
  return Permission.notification.status;
});
