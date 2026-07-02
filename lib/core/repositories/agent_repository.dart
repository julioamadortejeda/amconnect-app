import '../models/agent_profile.dart';

abstract class AgentRepository {
  Future<String> getMyName();
  Future<AgentProfile> getMe();
  Future<AgentProfile> updateMe({String? fullName, String? phone});
  Future<void> registerDeviceToken({required String token, required String platform});
  Future<void> deregisterDeviceToken({required String token});
}
