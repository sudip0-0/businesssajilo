import 'package:businesssajilo/core/utils/bill_search_match.dart';
import 'package:businesssajilo/domain/enums.dart';
import 'package:businesssajilo/domain/models/bill.dart';
import 'package:flutter_test/flutter_test.dart';

Bill _bill({
  String billNo = 'BS-0001',
  String? customerShopName,
  int grandTotal = 92500,
  DateTime? createdAt,
}) {
  return Bill(
    id: 'b1',
    businessId: 'biz',
    billNo: billNo,
    status: BillStatus.paid,
    createdBy: 'member',
    customerShopName: customerShopName,
    grandTotal: grandTotal,
    createdAt: createdAt ?? DateTime.utc(2026, 8, 11, 4, 30),
  );
}

void main() {
  group('billMatchesSearch', () {
    test('matches bill number', () {
      expect(billMatchesSearch(_bill(), query: 'BS-0001'), isTrue);
      expect(billMatchesSearch(_bill(), query: '0001'), isTrue);
      expect(billMatchesSearch(_bill(), query: 'ZZZ'), isFalse);
    });

    test('matches customer shop name and walk-in guest name', () {
      expect(
        billMatchesSearch(_bill(customerShopName: 'Shop 45'), query: 'shop'),
        isTrue,
      );
      expect(
        billMatchesSearch(
          _bill(customerShopName: 'umesh rai'),
          query: 'Umesh',
        ),
        isTrue,
      );
      expect(
        billMatchesSearch(_bill(customerShopName: 'Shop 45'), query: 'hari'),
        isFalse,
      );
    });

    test('matches amount via parseNpr and rupee digits', () {
      // 92500 paisa = रू 925
      expect(billMatchesSearch(_bill(), query: '925'), isTrue);
      expect(billMatchesSearch(_bill(), query: 'रू 925'), isTrue);
      expect(billMatchesSearch(_bill(), query: '100'), isFalse);
    });

    test('matches AD date fragments', () {
      final bill = _bill(createdAt: DateTime.utc(2026, 8, 11, 4, 30));
      expect(billMatchesSearch(bill, query: '11 Aug'), isTrue);
      expect(billMatchesSearch(bill, query: '2026-08-11'), isTrue);
      expect(billMatchesSearch(bill, query: '2026'), isTrue);
      expect(billMatchesSearch(bill, query: 'Jan 2020'), isFalse);
    });
  });

  test('billSearchAmountPaisa parses money queries', () {
    expect(billSearchAmountPaisa('925'), 92500);
    expect(billSearchAmountPaisa('रू 1,000'), 100000);
    expect(billSearchAmountPaisa('Shop 01'), isNull);
  });
}
