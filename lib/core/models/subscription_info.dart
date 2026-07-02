class PlanLimits {
  const PlanLimits({
    required this.chatMessagesMonthly,
    required this.ingestionsMonthly,
    required this.storageMb,
  });

  final int chatMessagesMonthly;
  final int ingestionsMonthly;
  final int storageMb;

  factory PlanLimits.fromJson(Map<String, dynamic> json) => PlanLimits(
        chatMessagesMonthly: json['chat_messages_monthly'] as int? ?? 0,
        ingestionsMonthly: json['ingestions_monthly'] as int? ?? 0,
        storageMb: json['storage_mb'] as int? ?? 0,
      );
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.slug,
    required this.name,
    required this.priceMxn,
    required this.priceUsd,
    required this.limits,
  });

  final String id;
  final String slug;
  final String name;
  final double priceMxn;
  final double priceUsd;
  final PlanLimits limits;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => SubscriptionPlan(
        id: json['id'] as String,
        slug: json['slug'] as String,
        name: json['name'] as String,
        priceMxn: (json['priceMxn'] as num).toDouble(),
        priceUsd: (json['priceUsd'] as num).toDouble(),
        limits: PlanLimits.fromJson(json['limits'] as Map<String, dynamic>),
      );
}

class UsageThisMonth {
  const UsageThisMonth({required this.chatMessages, required this.ingestions});

  final int chatMessages;
  final int ingestions;

  factory UsageThisMonth.fromJson(Map<String, dynamic> json) => UsageThisMonth(
        chatMessages: json['chatMessages'] as int? ?? 0,
        ingestions: json['ingestions'] as int? ?? 0,
      );
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.plan,
    required this.status,
    this.trialEndsAt,
    this.subscriptionExpiresAt,
    this.trialDaysRemaining,
    required this.usage,
  });

  final SubscriptionPlan plan;
  final String status;
  final String? trialEndsAt;
  final String? subscriptionExpiresAt;
  final int? trialDaysRemaining;
  final UsageThisMonth usage;

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) => SubscriptionInfo(
        plan: SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>),
        status: json['status'] as String,
        trialEndsAt: json['trialEndsAt'] as String?,
        subscriptionExpiresAt: json['subscriptionExpiresAt'] as String?,
        trialDaysRemaining: json['trialDaysRemaining'] as int?,
        usage: UsageThisMonth.fromJson(json['usage'] as Map<String, dynamic>),
      );
}
