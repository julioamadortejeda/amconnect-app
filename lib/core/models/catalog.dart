class Carrier {
  const Carrier({required this.id, required this.name, this.code, this.shortName});

  final String id;
  final String name;
  final String? code;
  final String? shortName;

  factory Carrier.fromJson(Map<String, dynamic> json) => Carrier(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String?,
        shortName: json['shortName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (code != null) 'code': code,
        if (shortName != null) 'shortName': shortName,
      };
}

class Branch {
  const Branch({required this.id, required this.name, this.code});

  final String id;
  final String name;
  final String? code;

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (code != null) 'code': code,
      };
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.carrierId,
    required this.branchId,
    this.code,
  });

  final String id;
  final String name;
  final String carrierId;
  final String branchId;
  final String? code;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        carrierId: json['carrierId'] as String? ?? json['carrier_id'] as String,
        branchId: json['branchId'] as String? ?? json['branch_id'] as String,
        code: json['code'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'carrierId': carrierId,
        'branchId': branchId,
        if (code != null) 'code': code,
      };
}

class PolicyStatus {
  const PolicyStatus({required this.id, required this.name, required this.code});

  final String id;
  final String name;
  final String code;

  factory PolicyStatus.fromJson(Map<String, dynamic> json) => PolicyStatus(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String? ?? '',
      );
}

class Currency {
  const Currency({required this.id, required this.name, required this.code});

  final String id;
  final String name;
  final String code;

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String? ?? '',
      );
}

class PaymentFrequency {
  const PaymentFrequency({required this.id, required this.name, required this.months, this.code});

  final String id;
  final String name;
  final int months;
  final String? code;

  factory PaymentFrequency.fromJson(Map<String, dynamic> json) => PaymentFrequency(
        id: json['id'] as String,
        name: json['name'] as String,
        months: json['months'] as int? ?? 12,
        code: json['code'] as String?,
      );
}

class PaymentMethod {
  const PaymentMethod({required this.id, required this.name, this.code});

  final String id;
  final String name;
  final String? code;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String?,
      );
}
