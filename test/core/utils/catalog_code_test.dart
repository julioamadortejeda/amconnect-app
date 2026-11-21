import 'package:amconnect/core/models/policy.dart';
import 'package:amconnect/core/utils/catalog_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa code cuando viene', () {
    expect(catalogCode('DIRECT_DEBIT', 'Domiciliación'), 'DIRECT_DEBIT');
  });

  test('sin code deriva del name (backend anterior)', () {
    expect(catalogCode(null, 'Direct Debit'), 'DIRECT_DEBIT');
    expect(catalogCode('', 'Bank Transfer'), 'BANK_TRANSFER');
    expect(catalogCode(null, 'Semi-annual'), 'SEMI_ANNUAL');
    expect(catalogCode(null, null), '');
  });

  test('Policy lee code de las relaciones y cae a name', () {
    final withCode = Policy.fromJson({
      'id': 'p1',
      'status': {'id': 's', 'code': 'ACTIVE', 'name': 'Vigente'},
      'paymentMethod': {'id': 'm', 'code': 'CREDIT_CARD', 'name': 'Tarjeta'},
      'paymentFrequency': {'id': 'f', 'code': 'MONTHLY', 'name': 'Mensual', 'months': 1},
    });
    expect(withCode.statusCode, 'ACTIVE');
    expect(withCode.paymentMethodCode, 'CREDIT_CARD');
    expect(withCode.frequencyCode, 'MONTHLY');

    final legacy = Policy.fromJson({
      'id': 'p2',
      'status': {'id': 's', 'name': 'Active'},
      'paymentMethod': {'id': 'm', 'name': 'Direct Debit'},
    });
    expect(legacy.statusCode, 'ACTIVE');
    expect(legacy.paymentMethodCode, 'DIRECT_DEBIT');
    expect(legacy.frequencyCode, '');
  });
}
