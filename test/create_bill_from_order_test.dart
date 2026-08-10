import 'package:businesssajilo/domain/models/order_item.dart';
import 'package:businesssajilo/features/billing/create_bill_from_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('billFromOrderDraftFromItems maps items and recomputes totals', () {
    final items = [
      const OrderItem(
        id: 'oi1',
        orderId: 'o1',
        productId: 'p1',
        qty: 2,
        productName: 'Rice',
      ),
      const OrderItem(
        id: 'oi2',
        orderId: 'o1',
        productId: 'p2',
        qty: 1,
        productName: null,
      ),
    ];

    final draft = billFromOrderDraftFromItems(
      items,
      ratesByProductId: {'p1': 5000, 'p2': 3000},
    );

    expect(draft.lines, hasLength(2));
    expect(draft.lines[0].productId, 'p1');
    expect(draft.lines[0].nameSnapshot, 'Rice');
    expect(draft.lines[0].qty, 2);
    expect(draft.lines[0].rate, 5000);
    expect(draft.lines[0].discount, 0);
    expect(draft.lines[0].lineTotal, 10000);

    expect(draft.lines[1].nameSnapshot, '—');
    expect(draft.lines[1].lineTotal, 3000);
    expect(draft.itemsTotal, 13000);
    expect(draft.discount, 0);
    expect(draft.grandTotal, 13000);
    expect(draft.isEmpty, isFalse);
  });

  test('empty items yield empty draft', () {
    final draft = billFromOrderDraftFromItems(
      const [],
      ratesByProductId: const {},
    );
    expect(draft.lines, isEmpty);
    expect(draft.itemsTotal, 0);
    expect(draft.isEmpty, isTrue);
  });

  test('billLineWithEdits recomputes line total', () {
    final line = billFromOrderDraftFromItems(
      const [
        OrderItem(
          id: 'oi1',
          orderId: 'o1',
          productId: 'p1',
          qty: 1,
          productName: 'Rice',
        ),
      ],
      ratesByProductId: const {'p1': 10000},
    ).lines.single;

    final edited = billLineWithEdits(line, qty: 3, rate: 2000, discount: 500);
    expect(edited.qty, 3);
    expect(edited.rate, 2000);
    expect(edited.discount, 500);
    expect(edited.lineTotal, 5500);
  });
}
