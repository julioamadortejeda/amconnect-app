import '../models/subscription_info.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionInfo> getInfo();
}
