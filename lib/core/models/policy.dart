import 'payment_schedule.dart';

class Policy {
  const Policy({
    required this.id,
    this.policyNumber,
    this.sumInsured,
    this.premium,
    this.startDate,
    this.endDate,
    this.renewalDate,
    this.nextPaymentDate,
    this.notes,
    this.deductible,
    this.product,
    this.status,
    this.currency,
    this.paymentFrequency,
    this.paymentMethod,
    this.contactId,
    this.contactName,
    this.paymentSchedule,
  });

  final String id;
  final String? policyNumber;
  final double? sumInsured;
  final double? premium;
  final String? startDate;
  final String? endDate;
  final String? renewalDate;
  final String? nextPaymentDate;
  final String? notes;
  final String? deductible;
  final PolicyProduct? product;
  final PolicyCatalog? status;
  final PolicyCurrency? currency;
  final PolicyFrequency? paymentFrequency;
  final PolicyCatalog? paymentMethod;
  final String? contactId;
  final String? contactName;

  /// Regla de pago y siguiente fecha, ya resueltas por el backend.
  final PaymentSchedule? paymentSchedule;

  String get productName => product?.name ?? '—';
  String get branchName  => product?.branchName ?? '—';
  String get carrierName => product?.carrierName ?? '—';
  String get statusCode  => status?.name.toUpperCase() ?? '';
  String get currencyCode => currency?.code ?? 'MXN';
  String get frequencyLabel => paymentFrequency?.name ?? '';

  bool matchesQuery(String q) {
    if (q.isEmpty) return true;
    final lower = q.toLowerCase();
    return (policyNumber?.toLowerCase().contains(lower) ?? false) ||
        productName.toLowerCase().contains(lower) ||
        branchName.toLowerCase().contains(lower) ||
        carrierName.toLowerCase().contains(lower) ||
        (contactName?.toLowerCase().contains(lower) ?? false) ||
        (notes?.toLowerCase().contains(lower) ?? false);
  }

  factory Policy.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final status  = json['status']  as Map<String, dynamic>?;
    final currency = json['currency'] as Map<String, dynamic>?;
    final freq    = json['paymentFrequency'] as Map<String, dynamic>?;
    final method  = json['paymentMethod'] as Map<String, dynamic>?;
    final contact = json['contact'] as Map<String, dynamic>?;
    final schedule = json['paymentSchedule'] as Map<String, dynamic>?;

    return Policy(
      id:              json['id'] as String,
      policyNumber:    json['policyNumber'] as String?,
      sumInsured:      (json['sumInsured'] as num?)?.toDouble(),
      premium:         (json['premium'] as num?)?.toDouble(),
      startDate:       json['startDate'] as String?,
      endDate:         json['endDate'] as String?,
      renewalDate:     json['renewalDate'] as String?,
      nextPaymentDate: json['nextPaymentDate'] as String?,
      notes:           json['notes'] as String?,
      deductible:      json['deductible'] as String?,
      product:  product  != null ? PolicyProduct.fromJson(product)  : null,
      status:   status   != null ? PolicyCatalog.fromJson(status)   : null,
      currency: currency != null ? PolicyCurrency.fromJson(currency) : null,
      paymentFrequency: freq != null ? PolicyFrequency.fromJson(freq) : null,
      paymentMethod: method != null ? PolicyCatalog.fromJson(method) : null,
      contactId: json['contactId'] as String? ?? contact?['id'] as String?,
      contactName: contact?['fullName'] as String? ?? contact?['full_name'] as String?,
      paymentSchedule: schedule != null ? PaymentSchedule.fromJson(schedule) : null,
    );
  }
}

class PolicyProduct {
  const PolicyProduct({
    required this.id,
    required this.name,
    this.branchName,
    this.carrierName,
  });

  final String id;
  final String name;
  final String? branchName;
  final String? carrierName;

  factory PolicyProduct.fromJson(Map<String, dynamic> json) {
    final branch  = json['branch']  as Map<String, dynamic>?;
    final carrier = json['carrier'] as Map<String, dynamic>?;
    return PolicyProduct(
      id:          json['id'] as String,
      name:        json['name'] as String,
      branchName:  branch?['name']  as String?,
      carrierName: carrier?['name'] as String?,
    );
  }
}

class PolicyCatalog {
  const PolicyCatalog({required this.id, required this.name});
  final String id;
  final String name;
  factory PolicyCatalog.fromJson(Map<String, dynamic> json) =>
      PolicyCatalog(id: json['id'] as String, name: json['name'] as String);
}

class PolicyCurrency {
  const PolicyCurrency({required this.id, required this.code, required this.name});
  final String id;
  final String code;
  final String name;
  factory PolicyCurrency.fromJson(Map<String, dynamic> json) => PolicyCurrency(
        id:   json['id']   as String,
        code: json['code'] as String,
        name: json['name'] as String,
      );
}

class PolicyFrequency {
  const PolicyFrequency({required this.id, required this.name, required this.months});
  final String id;
  final String name;
  final int months;
  factory PolicyFrequency.fromJson(Map<String, dynamic> json) => PolicyFrequency(
        id:     json['id']     as String,
        name:   json['name']   as String,
        months: json['months'] as int? ?? 12,
      );
}

extension PolicySlimExtension on Policy {
  Map<String, dynamic> toSlimMap() {
    return {
      'id': id,
      if (policyNumber != null) 'policyNumber': policyNumber,
      if (carrierName != '—') 'carrier': carrierName,
      if (branchName != '—') 'branch': branchName,
      if (productName != '—') 'product': productName,
      if (premium != null) 'premium': premium,
      'currency': currencyCode,
      if (statusCode.isNotEmpty) 'status': statusCode,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (renewalDate != null) 'renewalDate': renewalDate,
      if (nextPaymentDate != null) 'nextPaymentDate': nextPaymentDate,
    };
  }
}
