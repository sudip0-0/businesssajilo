import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PaymentMethod round-trips through Payment JSON', () {
    for (final method in PaymentMethod.values) {
      final payment = Payment(
        id: 'p1',
        businessId: 'b1',
        customerId: 'c1',
        amount: 500,
        method: method,
        receivedBy: 'm1',
      );
      final json = payment.toJson();
      expect(json['method'], method.name);
      expect(Payment.fromJson(json).method, method);
    }
  });
}
