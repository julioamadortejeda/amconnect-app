abstract class AgentRepository {
  Future<String> getMyName();
  Future<void> registerDeviceToken({required String token, required String platform});
  Future<void> deregisterDeviceToken({required String token});
}
