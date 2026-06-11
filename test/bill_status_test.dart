import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BillStatus round-trips through Bill JSON', () {
    for (final status in BillStatus.values) {
      final bill = Bill(
        id: 'b1',
        businessId: 'biz1',
        billNo: 'BS-0001',
        itemsTotal: 10000,
        grandTotal: 10000,
        status: status,
        createdBy: 'm1',
      );
      final json = bill.toJson();
      expect(json['status'], status.name);
      expect(Bill.fromJson(json).status, status);
    }
  });
}
